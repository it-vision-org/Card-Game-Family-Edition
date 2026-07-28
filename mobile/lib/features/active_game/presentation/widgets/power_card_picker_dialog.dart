import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/data/models/power_card_definition.dart';
import '../../../content/data/repositories/content_repository.dart';

/// Lets one participant pick their hand of `requiredCount` power cards
/// (repeats allowed) before the session starts. Returns the flat list of
/// chosen definition ids (with duplicates) on confirm, or null on cancel.
Future<List<String>?> showPowerCardPickerDialog(
  BuildContext context, {
  required String participantName,
  required int requiredCount,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => _PowerCardPickerDialog(
      participantName: participantName,
      requiredCount: requiredCount,
    ),
  );
}

final _powerCardDefinitionsProvider = FutureProvider.autoDispose<List<PowerCardDefinition>>((ref) {
  return ref.watch(contentRepositoryProvider).listPowerCards();
});

class _PowerCardPickerDialog extends ConsumerStatefulWidget {
  const _PowerCardPickerDialog({required this.participantName, required this.requiredCount});

  final String participantName;
  final int requiredCount;

  @override
  ConsumerState<_PowerCardPickerDialog> createState() => _PowerCardPickerDialogState();
}

class _PowerCardPickerDialogState extends ConsumerState<_PowerCardPickerDialog> {
  final Map<String, int> _counts = {};

  int get _total => _counts.values.fold(0, (sum, count) => sum + count);

  @override
  Widget build(BuildContext context) {
    final definitionsAsync = ref.watch(_powerCardDefinitionsProvider);

    return AlertDialog(
      title: Text('بطاقات القوة لـ ${widget.participantName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: definitionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('$error'),
          data: (definitions) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_total / ${widget.requiredCount}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: definitions.map((definition) {
                    final count = _counts[definition.id] ?? 0;
                    return ListTile(
                      title: Text(definition.title),
                      subtitle: Text(definition.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: count <= 0 ? null : () => setState(() => _counts[definition.id] = count - 1),
                          ),
                          Text('$count'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _total >= widget.requiredCount
                                ? null
                                : () => setState(() => _counts[definition.id] = count + 1),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _total == widget.requiredCount
              ? () {
                  final ids = <String>[];
                  _counts.forEach((id, count) {
                    ids.addAll(List.filled(count, id));
                  });
                  Navigator.of(context).pop(ids);
                }
              : null,
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}
