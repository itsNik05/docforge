import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/dark_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: DocForgeApp()));
}

class DocForgeApp extends StatelessWidget {
  const DocForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DocForge',
      theme: DarkTheme.theme,
      routerConfig: appRouter,
    );
  }
}