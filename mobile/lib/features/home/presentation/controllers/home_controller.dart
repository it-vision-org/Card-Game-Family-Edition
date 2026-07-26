import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/health_repository.dart';

final backendStatusProvider = FutureProvider<String>((ref) {
  return ref.watch(healthRepositoryProvider).checkBackend();
});