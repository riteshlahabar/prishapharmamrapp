import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Prisha Pharma MR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
