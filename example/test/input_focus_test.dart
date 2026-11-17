import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

bool inputHasFocus(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;

Future<void> expectFocusKeptAfterSending(WidgetTester tester) async {
  // Enter (send action on the keyboard).
  await tester.showKeyboard(find.byType(TextField));
  await tester.enterText(find.byType(TextField), 'first');
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
  expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty,
      reason: 'sent and cleared');
  expect(inputHasFocus(tester), isTrue, reason: 'after Enter');

  // Send button.
  await tester.enterText(find.byType(TextField), 'second');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pump();
  expect(inputHasFocus(tester), isTrue, reason: 'after the send button');

  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  expect(find.text('first'), findsOneWidget);
  expect(find.text('second'), findsOneWidget);
  expect(inputHasFocus(tester), isTrue, reason: 'after the messages were delivered');
}

void main() {
  testWidgets('basic demo keeps input focus after sending', (tester) async {
    await tester.pumpWidget(const MyApp(home: AppHome.rooms));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('기본 데모'), 200);
    await tester.tap(find.text('기본 데모'));
    await tester.pumpAndSettle();
    await expectFocusKeptAfterSending(tester);
  });

  testWidgets('room keeps input focus after sending', (tester) async {
    await tester.pumpWidget(const MyApp(home: AppHome.rooms));
    await tester.pumpAndSettle();
    await tester.tap(find.text('보통 방'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await expectFocusKeptAfterSending(tester);
  });
}
