import 'package:example/main.dart';
import 'package:example/site/site_locale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const fewKey = ValueKey('segment-PlaygroundHistory.few');

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
      expect(find.text('Got it: "hello"'), findsOneWidget);

      // Narrow screens switch between the preview and the settings.
      if (narrow) {
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(find.byKey(fewKey), 200,
          scrollable: find.descendant(
              of: find.byKey(const Key('playground-settings')),
              matching: find.byType(Scrollable)));
      await tester.ensureVisible(find.byKey(fewKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(fewKey));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      if (narrow) {
        await tester.tap(find.text('Preview'));
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
        if (size.width < 960) {
          await tester.tap(find.byTooltip('Menu'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(label).hitTestable().last);
        await tester.pumpAndSettle();
      }

      await open('Getting started');
      expect(find.text('Install the package'), findsOneWidget);

      await open('Examples');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Normal room').hitTestable(), findsWidgets);
    });
  }

  testWidgets('switching the language translates the site', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() => siteLocale.value = const Locale('en'));

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsWidgets);

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국어').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('컴포넌트 디자인'), findsOneWidget);
    expect(find.text('민지'), findsWidgets);
  });
}
