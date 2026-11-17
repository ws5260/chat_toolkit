import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(1400, 900), const Size(400, 800)]) {
    final narrow = size.width < 1024;

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
      expect(find.text('"hello" 잘 받았어요.'), findsOneWidget);

      // Narrow screens switch between the preview and the settings.
      if (narrow) {
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
      if (narrow) {
        await tester.tap(find.text('미리보기'));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('#2 '), findsOneWidget);
      expect(find.textContaining('#59'), findsNothing);
    });

    testWidgets('menu switches pages at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      Future<void> open(String label) async {
        if (size.width < 820) {
          await tester.tap(find.byTooltip('메뉴'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(label).hitTestable().last);
        await tester.pumpAndSettle();
      }

      await open('시작하기');
      expect(find.text('패키지를 설치해요'), findsOneWidget);

      await open('예제');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('보통 방').hitTestable(), findsWidgets);
    });
  }
}
