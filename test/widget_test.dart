import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';

void main() {
  testWidgets('Habit Tracker app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pump(); // allow first frame; async home may still load
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
