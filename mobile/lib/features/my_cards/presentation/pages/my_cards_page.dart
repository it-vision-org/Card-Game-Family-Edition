import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../content/data/models/card_category.dart';
import '../../../groups/data/models/group.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../data/models/my_card.dart';
import '../../data/repositories/my_card_repository.dart';
import '../controllers/my_cards_controller.dart';

class MyCardsPage extends ConsumerWidget {
  const MyCardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(myCardsProvider);
    final groupAsync = ref.watch(myGroupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('أسئلتي')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref, groupAsync.value),
        child: const Icon(Icons.add),
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ما زلت ما زدت حتى سؤال. اضغط على + باش تزيد سؤالك الأول.',
                ),
              ),
            );
          }
          final group = groupAsync.value;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return _MyCardTile(
                card: card,
                group: group,
                onEdit: () => _openForm(context, ref, group, existing: card),
                onDelete: () => _confirmDelete(context, ref, card),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Group? group, {
    MyCard? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MyCardForm(group: group, existing: existing),
    );
    ref.invalidate(myCardsProvider);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MyCard card,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السؤال'),
        content: const Text('باش يتحذف هذا السؤال نهائيًا. متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(myCardRepositoryProvider).deleteCard(card.id);
      ref.invalidate(myCardsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _MyCardTile extends StatelessWidget {
  const _MyCardTile({
    required this.card,
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  final MyCard card;
  final Group? group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = CardCategory(
      code: card.categoryCode,
      sortOrder: 0,
    ).arabicLabel;
    final playerNames = card.eligiblePlayerPublicIds.map((publicId) {
      for (final member in group?.members ?? const <GroupMember>[]) {
        if (member.publicId == publicId) return member.displayName;
      }
      return publicId;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    categoryLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (card.best)
                  Icon(
                    Icons.star,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(card.text, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: playerNames
                  .map((name) => Chip(label: Text(name)))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCardForm extends ConsumerStatefulWidget {
  const _MyCardForm({required this.group, this.existing});

  final Group? group;
  final MyCard? existing;

  @override
  ConsumerState<_MyCardForm> createState() => _MyCardFormState();
}

class _MyCardFormState extends ConsumerState<_MyCardForm> {
  late final TextEditingController _textController;
  String? _categoryCode;
  late final Set<String> _selectedPublicIds;
  bool _isBest = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.existing?.text ?? '');
    _categoryCode = widget.existing?.categoryCode;
    _selectedPublicIds = {
      ...(widget.existing?.eligiblePlayerPublicIds ?? const []),
    };
    _isBest = widget.existing?.best ?? false;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(cardCategoriesProvider);
    final members = widget.group?.members ?? const [];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'تعديل السؤال' : 'سؤال جديد',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('$error'),
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _categoryCode,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.code,
                        child: Text(c.arabicLabel),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryCode = value),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'نص السؤال',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'مين يجاوب على هذا السؤال؟',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: members.map((member) {
                final selected = _selectedPublicIds.contains(member.publicId);
                return FilterChip(
                  label: Text(member.displayName),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _selectedPublicIds.add(member.publicId);
                    } else {
                      _selectedPublicIds.remove(member.publicId);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isBest,
              onChanged: (value) => setState(() => _isBest = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('من أفضل الكارطات؟'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'حفظ التعديل' : 'إضافة السؤال'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (_categoryCode == null || text.isEmpty || _selectedPublicIds.isEmpty) {
      setState(
        () => _errorMessage =
            'لازم تختار الفئة، تكتب السؤال، وتحدد شكون يجاوب عليه',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(myCardRepositoryProvider);
      if (_isEditing) {
        await repository.updateCard(
          cardId: widget.existing!.id,
          categoryCode: _categoryCode!,
          text: text,
          eligiblePlayerPublicIds: _selectedPublicIds.toList(),
          best: _isBest,
        );
      } else {
        await repository.createCard(
          categoryCode: _categoryCode!,
          text: text,
          eligiblePlayerPublicIds: _selectedPublicIds.toList(),
          best: _isBest,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
