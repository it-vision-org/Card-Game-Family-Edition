import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(myGroupProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('بيناتنا الثلاثة'),
        actions: [
          IconButton(
            tooltip: 'قوانين اللعبة',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => context.push('/rules'),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            tooltip: 'خروج',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('ما نجمناش نجيبو العائلة:\n$error', textAlign: TextAlign.center),
        ),
        data: (group) {
          if (group == null) {
            return const Center(child: Text('ما فماش مجموعة عائلية بعد'));
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('مرحبا ${user?.displayName ?? ''} 👋', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...group.members.map(
                          (m) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline),
                            title: Text(m.displayName),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('ابدأ جلسة جديدة'),
                  onPressed: () => context.push('/session-setup', extra: group.id),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code),
                  label: const Text('انضم بكود الجلسة'),
                  onPressed: () => context.push('/join-session'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('الجلسات السابقة'),
                  onPressed: () => context.push('/history', extra: group.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
