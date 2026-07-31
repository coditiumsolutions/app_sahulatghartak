import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sahulat_ghar_tak/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SahulatApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
