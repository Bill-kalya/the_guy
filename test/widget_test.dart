import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'lib/app.dart';

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
}
