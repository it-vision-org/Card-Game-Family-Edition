import 'dart:async';

import 'package:between_three_mobile/features/auth/data/models/user_summary.dart';
import 'package:between_three_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:between_three_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthController extends AuthController {
  @override
  FutureOr<UserSummary?> build() => null;
}

void main() {
  testWidgets('shows the three seeded profiles and a PIN field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.textContaining('أحمد'), findsOneWidget);
    expect(find.textContaining('رحمة'), findsOneWidget);
    expect(find.textContaining('مامتي'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
