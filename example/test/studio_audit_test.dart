import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:example/l10n/app_localizations.dart';
import 'package:example/playground/playground_screen.dart';
import 'package:example/playground/playground_settings.dart';
import 'package:example/site/site_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Every studio setting must change what the chat shows. For each part, every setting the studio
/// offers is changed in turn, and the chat's render tree must differ afterwards.
class _Changes extends ChangeNotifier {
  void changed() => notifyListeners();
}

const _odd = Color(0xFFAA3355);
const _odd2 = Color(0xFF33AA77);

/// The settings the studio offers for [e] in [part], as (name, change) pairs.
List<(String, void Function())> _elementChanges(Part part, StudioElement e) {
  final rules = rulesOf(part);
  final textish = [ElementKind.content, ElementKind.text, ElementKind.badge].contains(e.kind);
  return [
    if (textish || e.kind == ElementKind.field) ...[
      ('fontSize', () => e.fontSize += 5),
      ('color', () => e.color = _odd),
    ],
    if (textish) ('bold', () => e.bold = !e.bold),
    if (e.kind == ElementKind.text || e.kind == ElementKind.badge) ...[
      if (e.source == TextSource.literal) ('text', () => e.text = 'Zq'),
      if (e.source == TextSource.readState) ...[
        ('text (unread)', () => e.text = 'Un'),
        ('text2 (read)', () => e.text2 = 'Rd'),
      ],
      if (e.source == TextSource.time) ('use24h', () => e.use24h = !e.use24h),
      if (e.source == TextSource.date) ('weekday', () => e.weekday = !e.weekday),
      if (rules.sources.length > 1)
        ('source', () {
          e.source = rules.sources[(rules.sources.indexOf(e.source) + 1) % rules.sources.length];
          // As the studio does: typed text starts with something.
          if (e.source == TextSource.literal && e.text.isEmpty) e.text = 'Typed';
        }),
    ],
    if (e.kind == ElementKind.icon) ...[
      ('icon', () => e.icon = e.icon == StudioIcon.bolt ? StudioIcon.star : StudioIcon.bolt),
      if (part == Part.read)
        ('icon2 (read)', () => e.icon2 = e.icon2 == StudioIcon.star ? StudioIcon.bolt : StudioIcon.star),
      ('size', () => e.size += 6),
      ('color', () => e.color = _odd),
    ],
    if (e.kind == ElementKind.field) ...[
      // The search field holds the query, so its hint is hidden.
      if (part != Part.search) ('hint', () => e.text = 'Hint here'),
      ('background', () => e.background = _odd2),
      ('radius', () => e.radius = e.radius == 4 ? 9 : 4),
    ],
    if (e.kind == ElementKind.button) ...[
      ('icon', () => e.icon = e.icon == StudioIcon.bolt ? StudioIcon.star : StudioIcon.bolt),
      ('color', () => e.color = _odd),
      ('look text', () => e.look = ButtonLook.text),
      ('label', () => e.text = 'Go'),
      ('fontSize (text button)', () => e.fontSize += 5),
      ('look filled', () => e.look = ButtonLook.filled),
      ('size', () => e.size += 6),
      ('background', () => e.background = _odd2),
      ('radius', () => e.radius = e.radius == 4 ? 9 : 4),
      ('look icon', () => e.look = ButtonLook.icon),
    ],
    if (e.kind == ElementKind.avatar) ...[
      ('size', () => e.size += 8),
      ('roundness', () => e.radius = e.radius == 0.1 ? 0.4 : 0.1),
      ('background', () => e.background = _odd2),
      ('color', () => e.color = _odd),
    ],
    if (e.kind == ElementKind.divider) ...[
      ('thickness', () => e.size += 2),
      ('color', () => e.color = _odd),
    ],
    ('hide', () => e.visible = false),
    ('show', () => e.visible = true),
  ];
}

List<(String, void Function())> _boxChanges(Part part, StudioSpec spec) {
  final box = spec.box;
  final placed = part == Part.separator;
  return [
    ('box background', () => box.background = _odd2),
    ('box gradient', () => box.gradientTo = _odd),
    ('box border', () => box.borderWidth = 3),
    ('box border color', () => box.borderColor = _odd),
    ('box radius', () => box.radius = box.radius == 5 ? 11 : 5),
    ('box shadow', () => box.shadow = box.shadow == 6 ? 14 : 6),
    ('box padding h', () => box.paddingH += 7),
    ('box padding v', () => box.paddingV += 7),
    if (box.fill || box.align != StudioAlign.center) ('box margin h', () => box.marginH += 7),
    ('box margin v', () => box.marginV += 7),
    // Taller than any content, so the minimum shows.
    ('box min height', () => box.height = 600),
    // Back, so the other parts stay on screen.
    ('box min height off', () => box.height = 0),
    if (placed) ...[
      if (!box.fill) ('box align', () => box.align = box.align == StudioAlign.end ? StudioAlign.start : StudioAlign.end),
      ('box fill', () => box.fill = !box.fill),
    ],
  ];
}

List<(String, void Function())> _layoutChanges(StudioSpec spec) {
  final many = spec.elements.where((e) => e.visible).length > 1;
  return [
    if (many) ('gap', () => spec.gap += 9),
    if (spec.axis == StudioAxis.row &&
        spec.box.fill &&
        !spec.elements.any((e) =>
            e.visible && (e.kind == ElementKind.field || e.kind == ElementKind.divider)))
      ('main align', () => spec.main = spec.main == StudioAlign.end ? StudioAlign.start : StudioAlign.end),
    if (many) ('axis', () => spec.axis = spec.axis == StudioAxis.row ? StudioAxis.column : StudioAxis.row),
    if (many)
      ('cross align', () => spec.cross = spec.cross == StudioAlign.end ? StudioAlign.start : StudioAlign.end),
  ];
}

void main() {
  for (final part in Part.values) {
    testWidgets('every studio setting of $part shows in the chat', (tester) async {
      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final s = PlaygroundSettings()
        ..autoReply = false
        ..latencyMs = 0
        ..readOnly = part == Part.readOnly
        ..myProfile = true;
      s.looks[part] = Look.custom;
      final changes = _Changes();

      await tester.pumpWidget(MaterialApp(
        theme: buildSiteTheme(languageCode: 'en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PlaygroundPage(settings: s, changes: changes)),
      ));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Make the part show.
      final inChat = find.byType(Chat);
      switch (part) {
        case Part.search:
          await tester.tap(find.byTooltip('Search'));
          await tester.pumpAndSettle();
          await tester.enterText(
              find.descendant(of: inChat, matching: find.byType(TextField)).first, 'Sure');
          await tester.testTextInput.receiveAction(TextInputAction.send);
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        case Part.read:
          // An unread message besides the read ones.
          final input = find.descendant(of: inChat, matching: find.byType(TextField)).last;
          await tester.enterText(input, 'unread one');
          await tester.testTextInput.receiveAction(TextInputAction.send);
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        case Part.notice:
          await tester.drag(find.byType(Scrollable).first, const Offset(0, 900));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Receive'));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle();
        default:
      }

      // A blinking cursor would change the picture by itself.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // What is on screen, pixel by pixel.
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.ancestor(of: inChat, matching: find.byType(RepaintBoundary)).first);
      Future<List<int>> dump() async => (await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData();
            image.dispose();
            return bytes!.buffer.asUint8List().toList();
          }))!;
      // The render tree without what changes every frame (hashes, layers, repaint statistics).
      String tree() => tester
          .renderObject(inChat)
          .toStringDeep()
          .replaceAll(RegExp(r'#[0-9a-f]{5}'), '')
          .split('\n')
          .where((line) => !RegExp('layer|metrics:|diagnosis:|repaint boundary|should|kept|cursorColor')
              .hasMatch(line))
          .join('\n');

      var before = await dump();
      var beforeTree = tree();
      final noEffect = <String>[];

      Future<void> check(String name, void Function() change) async {
        change();
        changes.changed();
        await tester.pump();
        await tester.pumpAndSettle();
        final after = await dump();
        final afterTree = tree();
        // Changed if either the picture or the layout changed.
        if (listEquals(after, before) && afterTree == beforeTree) noEffect.add(name);
        before = after;
        beforeTree = afterTree;
      }

      // The check itself: a change that changes nothing must be caught.
      await check('nothing', () {});
      expect(noEffect, ['nothing'], reason: 'the render tree dump is not stable');
      noEffect.clear();

      final specs = [s.spec(part), if (part == Part.bubble) s.receiverBubble];
      for (final (i, spec) in specs.indexed) {
        final tag = i == 0 ? '' : 'receiver ';
        for (final e in List.of(spec.elements)) {
          for (final (name, change) in _elementChanges(part, e)) {
            await check('$tag${e.kind.name}[${spec.elements.indexOf(e)}].$name', change);
          }
        }
        for (final (name, change) in _layoutChanges(spec)) {
          await check('$tag$name', change);
        }
        for (final (name, change) in _boxChanges(part, spec)) {
          await check('$tag$name', change);
        }
      }
      // Icons are drawn with a font the test does not load, so a new icon looks the same here;
      // the browser shows it.
      noEffect.removeWhere((n) => RegExp(r'\.icon2? \(read\)$|\.icon$').hasMatch(n));
      expect(noEffect, isEmpty, reason: '$part: settings with no effect: $noEffect');
    });
  }
}
