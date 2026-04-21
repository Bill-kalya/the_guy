import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'routes/app_router.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

class TheGuyApp extends ConsumerStatefulWidget {
  const TheGuyApp({super.key});

  @override
  ConsumerState<TheGuyApp> createState() => _TheGuyAppState();
}

class _TheGuyAppState extends ConsumerState<TheGuyApp> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndInitialize();
  }

  void _checkAuthAndInitialize() async {
    await ref.read(authProvider.notifier).checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'The Guy',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
