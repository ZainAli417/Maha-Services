import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Constant/Splash.dart';

Future<void> _run(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 1));

  // Force lower sections (IntrinsicHeight + _Reveal) to lay out by scrolling.
  final sc = find.byType(Scrollable).first;
  await tester.drag(sc, const Offset(0, -1200));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.drag(sc, const Offset(0, -3000));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.drag(sc, const Offset(0, -6000));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  for (final size in const [
    Size(1440, 900),
    Size(1000, 800),
    Size(850, 800), // stacked hero (<900)
    Size(700, 900),
    Size(600, 900),
    Size(375, 812), // mobile
  ]) {
    testWidgets('LandingPage @ $size', (tester) async {
      await _run(tester, size);
    });
  }
}
