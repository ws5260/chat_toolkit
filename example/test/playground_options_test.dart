import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:example/main.dart';
import 'package:example/playground/playground_settings.dart';
import 'package:example/playground/studio_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the playground on a screen tall enough to build every card.
Future<void> _open(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
  await tester.pump(const Duration(seconds: 1)); // server latency
  await tester.pumpAndSettle();
  if (width < 1024) {
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

/// Taps every match of [finder] once, re-finding after each tap since rows come and go.
Future<int> _tapAll(WidgetTester tester, Finder finder) async {
  var i = 0;
  while (i < finder.evaluate().length) {
    await _tap(tester, finder.at(i));
    i++;
  }
  return i;
}

Finder _inStudio(Finder f) =>
    find.descendant(of: find.byKey(const Key('studio')), matching: f);

Finder get _segments => find.byWidgetPredicate((w) =>
    w is GestureDetector &&
    w.key is ValueKey &&
    '${(w.key! as ValueKey).value}'.startsWith('segment-'));

void main() {
  // Desktop (studio beside the chat), laptop (studio in place of the settings), mobile (split).
  for (final width in [1600.0, 1200.0, 400.0]) {
    testWidgets('every part can be designed at width $width', (tester) async {
      await _open(tester, width);
      for (final part in Part.values) {
        // Custom first, so the edit button is there.
        final edit = find.byKey(ValueKey('edit-${part.name}'));
        if (edit.evaluate().isEmpty) {
          await _tap(
              tester,
              find.descendant(
                  of: find.byKey(ValueKey('look-${part.name}')),
                  matching: find.byKey(ValueKey('segment-${Look.custom}'))));
        }
        // Choosing custom opens the studio; otherwise the edit button does.
        if (find.byKey(const Key('studio')).evaluate().isEmpty) await _tap(tester, edit);
        expect(find.byKey(const Key('studio')), findsOneWidget, reason: '$part');

        // Add one of each element, then try every choice of the structure and box tabs.
        for (var i = 0; i < 3; i++) {
          final add = _inStudio(find.byKey(const Key('studio-add')));
          if (add.evaluate().isEmpty) break; // nothing more can be added
          await _tap(tester, add);
          final items = find.byType(PopupMenuItem<ElementKind>);
          if (i >= items.evaluate().length) {
            await tester.tapAt(Offset.zero);
            await tester.pumpAndSettle();
            break;
          }
          await _tap(tester, items.at(i));
        }
        await _tapAll(tester, _inStudio(_segments));
        await _tap(tester, _inStudio(find.byKey(const ValueKey('segment-1'))).last); // box tab
        await _tapAll(tester, _inStudio(find.byType(Switch)));
        await _tap(tester, _inStudio(find.byKey(const ValueKey('segment-2'))).last); // code tab
        await _tap(tester, _inStudio(find.byKey(const ValueKey('segment-0'))).last);
        await _tap(tester, find.byKey(const Key('studio-close')));
        if (width < 1024 && find.text('Settings').evaluate().isNotEmpty) {
          await tester.tap(find.text('Settings'));
          await tester.pumpAndSettle();
        }
      }
      expect(find.byType(Chat, skipOffstage: false), findsWidgets);
    });
  }

  testWidgets('an element removed in the studio leaves the chat', (tester) async {
    await _open(tester, 1600);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    // Choosing custom opens the studio.
    await _tap(tester, find.descendant(
        of: find.byKey(const ValueKey('look-search')),
        matching: find.byKey(ValueKey('segment-${Look.custom}'))));
    final close = find.descendant(of: find.byType(Chat), matching: find.byTooltip('Close search'));
    expect(close, findsOneWidget);
    // The close button is the last element.
    await _tap(tester, _inStudio(find.byTooltip('Delete')).last);
    expect(close, findsNothing);
  });

  testWidgets('the search starts with the toolkit bar', (tester) async {
    await _open(tester, 1600);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchBar), findsOneWidget);
    await _tap(tester, find.descendant(
        of: find.byKey(const ValueKey('look-search')),
        matching: find.byKey(ValueKey('segment-${Look.custom}'))));
    expect(find.byType(ChatSearchBar), findsNothing);
  });

  group('studio code', () {
    test('the search bar is wired to the search controller', () {
      final spec = defaultSpec(Part.search)..box.radius = 7;
      final code = studioCode(Part.search, spec);
      expect(code, contains('ListenableBuilder('));
      expect(code, contains('search.hasOlder ? search.showOlder : null'));
      expect(code, contains('onSubmitted: search.search'));
      expect(code, contains('BorderRadius.circular(7)'));
    });

    test('hidden elements are left out', () {
      final spec = defaultSpec(Part.search);
      spec.elements.firstWhere((e) => e.kind == ElementKind.badge).visible = false;
      expect(studioCode(Part.search, spec), isNot(contains('search.results.length')));
    });
  });
}
