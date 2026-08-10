import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_guy/app.dart';
import 'package:the_guy/features/admin/presentation/widgets/admin_shell.dart';

void main() {
  testWidgets('The Guy app launches', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return ProviderScope(
            child: const TheGuyApp(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('The Guy'), findsOneWidget); // Adjust based on your app's content
  });

  testWidgets('Admin shell uses compact navigation on narrower widths', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SizedBox(
            width: 900,
            child: AdminShell(
              body: const SizedBox.shrink(),
              currentRoute: 'providers',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin Center'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
  });
}
