import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sift/core/theme/app_theme.dart';

// Full app boot isn't exercised here — SiftApp talks to Isar, photo_manager,
// and other platform channels that aren't available in the widget test
// harness. This verifies the themes we build actually render without
// throwing, which is what would otherwise blow up at startup.
void main() {
  testWidgets('Dark theme renders a basic scaffold', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildSiftTheme(),
      home: const Scaffold(body: Center(child: Text('Sift'))),
    ));

    expect(find.text('Sift'), findsOneWidget);
  });

  testWidgets('Light theme renders a basic scaffold', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildSiftLightTheme(),
      home: const Scaffold(body: Center(child: Text('Sift'))),
    ));

    expect(find.text('Sift'), findsOneWidget);
  });
}
