import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../active_game/data/repositories/session_repository.dart';
import '../../../content/data/models/card_category.dart';
import '../../../content/data/repositories/content_repository.dart';

enum _LengthPreset { short, long, custom }

class SessionSetupPage extends ConsumerStatefulWidget {
  const SessionSetupPage({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<SessionSetupPage> createState() => _SessionSetupPageState();
}

class _SessionSetupPageState extends ConsumerState<SessionSetupPage> {
  String _gameMode = 'MIXED';
  String? _categoryCode;
  _LengthPreset _lengthPreset = _LengthPreset.short;
  double _customLength = 20;
  bool _scoringEnabled = true;
  bool _submitting = false;
  String? _errorMessage;

  static const _modes = [
    ('MIXED', 'خليط من كل الفئات'),
    ('CATEGORY', 'فئة معيّنة'),
    ('BEST_CARDS', 'أفضل الكارطات'),
    ('CUSTOM', 'مخصّص'),
  ];

  int get _requestedCardCount {
    switch (_lengthPreset) {
      case _LengthPreset.short:
        return 15;
      case _LengthPreset.long:
        return 30;
      case _LengthPreset.custom:
        return _customLength.round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('جلسة جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('اختار نمط اللعب', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.map((mode) {
                final (code, label) = mode;
                return ChoiceChip(
                  label: Text(label),
                  selected: _gameMode == code,
                  onSelected: (_) => setState(() => _gameMode = code),
                );
              }).toList(),
            ),
            if (_gameMode == 'CATEGORY') ...[
              const SizedBox(height: 16),
              Text('اختار الفئة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('$error'),
                data: (categories) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((CardCategory category) {
                    return ChoiceChip(
                      label: Text(category.arabicLabel),
                      selected: _categoryCode == category.code,
                      onSelected: (_) => setState(() => _categoryCode = category.code),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text('طول الجلسة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<_LengthPreset>(
              segments: const [
                ButtonSegment(value: _LengthPreset.short, label: Text('قصيرة (15)')),
                ButtonSegment(value: _LengthPreset.long, label: Text('طويلة (30)')),
                ButtonSegment(value: _LengthPreset.custom, label: Text('مخصّصة')),
              ],
              selected: {_lengthPreset},
              onSelectionChanged: (selection) => setState(() => _lengthPreset = selection.first),
            ),
            if (_lengthPreset == _LengthPreset.custom) ...[
              Slider(
                value: _customLength,
                min: 3,
                max: 60,
                divisions: 57,
                label: _customLength.round().toString(),
                onChanged: (value) => setState(() => _customLength = value),
              ),
              Center(child: Text('${_customLength.round()} كارطة')),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('تفعيل النقاط'),
              value: _scoringEnabled,
              onChanged: (value) => setState(() => _scoringEnabled = value),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إنشاء الجلسة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_gameMode == 'CATEGORY' && _categoryCode == null) {
      setState(() => _errorMessage = 'لازم تختار فئة');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final session = await ref.read(sessionRepositoryProvider).createSession(
            groupId: widget.groupId,
            gameMode: _gameMode,
            categoryCode: _gameMode == 'CATEGORY' ? _categoryCode : null,
            requestedCardCount: _requestedCardCount,
            scoringEnabled: _scoringEnabled,
          );

      if (!mounted) return;
      context.pushReplacement('/session/${session.id}/lobby');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

final _categoriesProvider = FutureProvider.autoDispose<List<CardCategory>>((ref) {
  return ref.watch(contentRepositoryProvider).listCategories();
});
