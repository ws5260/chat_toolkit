import 'package:example/main.dart';
import 'package:example/playground/playground_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(1400, 900), const Size(400, 800)]) {
    testWidgets('playground loads, sends and changes settings at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(seconds: 1)); // server latency
      await tester.pumpAndSettle();
      expect(find.textContaining('#59'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('"hello" 잘 받았습니다.'), findsOneWidget);

      // Narrow screens show the settings in a tab.
      if (size.width < 760) {
        await tester.tap(find.text('설정'));
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(find.text('3건'), 200,
          scrollable: find.descendant(
              of: find.byKey(const Key('playground-settings')),
              matching: find.byType(Scrollable)));
      await tester.ensureVisible(find.text('3건'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3건'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      if (size.width < 760) {
        await tester.tap(find.text('미리보기'));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('#2 '), findsOneWidget);
      expect(find.textContaining('#59'), findsNothing);
    });
  }

  test('generated code lists only non-default options', () {
    final s = PlaygroundSettings()
      ..reverse = false
      ..appearMs = 0
      ..messagesStartAtTop = false;
    final code = playgroundCode(s);
    expect(code, contains('ChatController(reverse: false)'));
    expect(code, isNot(contains('messageAppearAnimationDuration')));
    expect(code, isNot(contains('messagesStartAtTop')));
  });
}
