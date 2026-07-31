import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_semantic_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../data/repositories/settings_repository.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final groupAsync = ref.watch(myGroupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ChangePinSection(),
          const Divider(height: 40),
          Card(
            child: ListTile(
              leading: const Icon(Icons.style_outlined),
              title: const Text('أسئلتي'),
              subtitle: const Text('زيد أسئلتك الخاصة وإدارتها'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/my-cards'),
            ),
          ),
          if (user?.isAdmin == true) ...[
            const Divider(height: 40),
            const _PowerCardsPerPlayerSection(),
            const Divider(height: 40),
            groupAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('$error'),
              data: (group) => group == null
                  ? const SizedBox.shrink()
                  : _TrashSection(groupId: group.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangePinSection extends ConsumerStatefulWidget {
  const _ChangePinSection();

  @override
  ConsumerState<_ChangePinSection> createState() => _ChangePinSectionState();
}

class _ChangePinSectionState extends ConsumerState<_ChangePinSection> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  bool _submitting = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الرمز السري', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'الرمز الحالي',
                counterText: '',
              ),
            ),
            TextField(
              controller: _newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'الرمز الجديد',
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(
                            context,
                          ).extension<AppSemanticColors>()!.success,
                  ),
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
                  : const Text('تغيير الرمز السري'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .changePin(
            currentPin: _currentPinController.text,
            newPin: _newPinController.text,
          );
      _currentPinController.clear();
      _newPinController.clear();
      setState(() {
        _isError = false;
        _message = 'تم تغيير الرمز السري بنجاح';
      });
    } on ApiException catch (e) {
      setState(() {
        _isError = true;
        _message = e.message;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _PowerCardsPerPlayerSection extends ConsumerStatefulWidget {
  const _PowerCardsPerPlayerSection();

  @override
  ConsumerState<_PowerCardsPerPlayerSection> createState() =>
      _PowerCardsPerPlayerSectionState();
}

class _PowerCardsPerPlayerSectionState
    extends ConsumerState<_PowerCardsPerPlayerSection> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(gameSettingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'عدد بطاقات القوة لكل لاعب',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('$error'),
              data: (settings) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _submitting || settings.powerCardsPerPlayer <= 1
                        ? null
                        : () => _update(settings.powerCardsPerPlayer - 1),
                  ),
                  Text(
                    '${settings.powerCardsPerPlayer}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _submitting || settings.powerCardsPerPlayer >= 50
                        ? null
                        : () => _update(settings.powerCardsPerPlayer + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _update(int value) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .updatePowerCardsPerPlayer(value);
      ref.invalidate(gameSettingsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _TrashSection extends ConsumerStatefulWidget {
  const _TrashSection({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_TrashSection> createState() => _TrashSectionState();
}

class _TrashSectionState extends ConsumerState<_TrashSection> {
  final Set<String> _selectedCardIds = {};
  bool _restoring = false;

  Future<void> _restoreIds(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    setState(() => _restoring = true);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .restoreCardsBulk(widget.groupId, cardIds);
      _selectedCardIds.removeAll(cardIds);
      ref.invalidate(trashProvider(widget.groupId));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trashAsync = ref.watch(trashProvider(widget.groupId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الكارطات المحذوفة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            trashAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('$error'),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Text('ما فماش كارطات محذوفة حاليًا');
                }
                final selectedCount = _selectedCardIds.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _restoring
                                ? null
                                : () => _restoreIds(
                                    entries.map((e) => e.cardId).toList(),
                                  ),
                            icon: const Icon(Icons.restore),
                            label: const Text('استرجاع الكل'),
                          ),
                        ),
                        if (selectedCount > 0) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _restoring
                                  ? null
                                  : () =>
                                        _restoreIds(_selectedCardIds.toList()),
                              icon: const Icon(Icons.restore),
                              label: Text('استرجاع ($selectedCount)'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...entries.map((entry) {
                      final selected = _selectedCardIds.contains(entry.cardId);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selected,
                        onChanged: _restoring
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedCardIds.add(entry.cardId);
                                  } else {
                                    _selectedCardIds.remove(entry.cardId);
                                  }
                                });
                              },
                        title: Text(entry.externalKey),
                        secondary: TextButton(
                          onPressed: _restoring
                              ? null
                              : () => _restoreIds([entry.cardId]),
                          child: const Text('استرجاع'),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
