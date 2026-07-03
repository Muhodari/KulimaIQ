import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kulimaiq_app/main.dart';

void main() {
  testWidgets('KulimaIQ app loads MaterialApp shell', (WidgetTester tester) async {
    await tester.pumpWidget(const KulimaIQApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
