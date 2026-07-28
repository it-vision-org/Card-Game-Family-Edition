import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_summary.dart';
import '../../data/repositories/auth_repository.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserSummary?>(AuthController.new);

class AuthController extends AsyncNotifier<UserSummary?> {
  @override
  FutureOr<UserSummary?> build() {
    return ref.watch(authRepositoryProvider).restoreSession();
  }

  Future<void> login({required String publicId, required String pin}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(publicId: publicId, pin: pin),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
