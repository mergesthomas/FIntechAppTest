import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/secure/flutter_secure_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        secureStoreProvider.overrideWith((ref) => FlutterSecureStore()),
      ],
      child: const FintechApp(),
    ),
  );
}
