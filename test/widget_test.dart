import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habit_companion/main.dart';
import 'package:habit_companion/state/app_state.dart';

void main() {
  testWidgets('child screen: seeded habit, tap reveals awaiting-approval',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.boot(now: () => DateTime(2026, 6, 10, 9));

    await tester.pumpWidget(HabitCompanionApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('이불 정리'), findsOneWidget);
    expect(find.text('Lv.1'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '했어!'));
    await tester.pumpAndSettle();

    expect(find.text('성장 준비 완료 · 승인 대기'), findsOneWidget);
  });
}
