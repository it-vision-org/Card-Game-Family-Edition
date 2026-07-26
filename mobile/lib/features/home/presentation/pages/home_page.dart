import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/home_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendStatus = ref.watch(backendStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بيناتنا الثلاثة'),
      ),
      body: Center(
        child: backendStatus.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text(
            'Backend connection failed:\n$error',
            textAlign: TextAlign.center,
          ),
          data: (status) => Text(
            'Backend: $status',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}