import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> bootstrap() async {
  runApp(
    const ProviderScope(
      child: BetweenThreeApp(),
    ),
  );
}