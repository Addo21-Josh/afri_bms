import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/offline_banner.dart';

class AfriBmsApp extends ConsumerWidget {
  const AfriBmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Afri_BMS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        return Scaffold(
          body: Column(
            children: [
              const OfflineBanner(),
              if (child != null) Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
