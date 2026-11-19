import 'dart:async';

import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _TextElement extends MessageElement {
  const _TextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) => SearchHighlightedText(text);

  @override
  _TextElement copyWith() => _TextElement(text);
}

void main() {
  final base = DateTime(2026, 3, 1, 9);
  Message message(int i) => ReceiverMessage(
    id: 'm${(i + 1000).toString().padLeft(6, '0')}',
    name: 'other',
    timestamp: base.add(Duration(minutes: 7 * i)).toIso8601String(),
    elements: [_TextElement(i % 10 == 0 ? 'msg $i apple' : 'msg $i')],
  );
  String idOf(int i) => message(i).id;
  List<Message> range(int from, int to) => [for (var i = from; i < to; i++) message(i)];

  late ChatController chat;
  late ChatSearchController search;
  late List<String> loadedAround;

  Future<void> pumpChat(
    WidgetTester tester, {
    int loaded = 100,
    Duration loadDelay = Duration.zero,
    ChatConfiguration configuration = const ChatConfiguration(),
  }) async {
    loadedAround = [];
    chat = ChatController()..setMessages(range(200 - loaded, 200));
    search = ChatSearchController(
      chatController: chat,
      // Once per match, so the search steps through the matches of a message.
      onSearch: (query) async => [
        for (var i = 199; i >= 0; i--)
          for (final _ in query.allMatches((message(i).elements.single as _TextElement).text))
            idOf(i),
      ],
      onLoadAround: (id) async {
        loadedAround.add(id);
        await Future<void>.delayed(loadDelay);
        final i = int.parse(id.substring(1)) - 1000;
        await chat.setMessagesAround(
          range((i - 15).clamp(0, 200), (i + 16).clamp(0, 200)),
          anchorMessageId: id,
          highlight: false,
        );
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Chat(
            chatController: chat,
            searchController: search,
            configuration: configuration,
            customInputField: (context, controller) => const TextField(key: Key('input')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    search.dispose();
    chat.dispose();
  }

  // The matched part of a SearchHighlightedText, and its background.
  Finder textOf(String label) => find.byWidgetPredicate(
    (w) => w is Text && (w.textSpan?.toPlainText() ?? w.data ?? '').contains(label),
  );

  Color? matchBackground(WidgetTester tester, String label, String match) {
    final text = tester.widget<Text>(textOf(label));
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    return spans.firstWhere((s) => s.text == match).style?.backgroundColor;
  }

  List<Color?> matchBackgrounds(WidgetTester tester, String label, String match) {
    final text = tester.widget<Text>(textOf(label));
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    return [
      for (final s in spans)
        if (s.text == match) s.style?.backgroundColor,
    ];
  }

  const current = Color(0xFFFFB020);
  const other = Color(0xFFFFE58F);

  testWidgets('search shows the newest result and marks the current one', (tester) async {
    await pumpChat(tester);
    search.open();
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchBar), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'apple');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(search.currentMessageId, idOf(190));
    expect(find.text('1/20'), findsOneWidget);
    expect(textOf('msg 190 apple'), findsOneWidget);

    unawaited(search.showOlder());
    await tester.pumpAndSettle();
    expect(search.currentMessageId, idOf(180));
    expect(find.text('2/20'), findsOneWidget);
    expect(matchBackground(tester, 'msg 180 apple', 'apple'), current);

    // Other visible matches are marked more lightly than the current result.
    unawaited(search.search('msg 19'));
    await tester.pumpAndSettle();
    expect(search.currentMessageId, idOf(199));
    expect(matchBackground(tester, 'msg 199', 'msg 19'), current);
    expect(matchBackground(tester, 'msg 198', 'msg 19'), other);

    search.close();
    await tester.pumpAndSettle();
    expect(find.byType(ChatSearchBar), findsNothing);
    final plain = tester.widget<Text>(find.text('msg 199'));
    expect(plain.data, 'msg 199');

    await dispose(tester);
  });

  testWidgets('the matches in one message are shown one at a time', (tester) async {
    await pumpChat(tester);
    unawaited(search.search('1'));
    await tester.pumpAndSettle();
    expect(search.currentMessageId, idOf(199));
    expect(search.currentMatchIndex, isNull);
    // 198 down to 192 have one match each; "msg 191" has two.
    for (var i = 0; i < 8; i++) {
      unawaited(search.showOlder());
      await tester.pumpAndSettle();
    }
    // Going older (up the screen) starts at the message's last match.
    expect(search.currentMessageId, idOf(191));
    expect(search.currentMatchIndex, 1);
    expect(matchBackgrounds(tester, 'msg 191', '1'), [other, current]);

    unawaited(search.showOlder());
    await tester.pumpAndSettle();
    expect(search.currentMessageId, idOf(191));
    expect(search.currentMatchIndex, 0);
    expect(matchBackgrounds(tester, 'msg 191', '1'), [current, other]);

    unawaited(search.showOlder());
    await tester.pumpAndSettle();
    expect(search.currentMessageId, idOf(190));
    expect(matchBackgrounds(tester, 'msg 191', '1'), [other, other]);

    unawaited(search.showNewer());
    await tester.pumpAndSettle();
    expect(search.currentMatchIndex, 0);
    expect(matchBackgrounds(tester, 'msg 191', '1'), [current, other]);

    await dispose(tester);
  });

  testWidgets('a result that is not loaded is loaded around', (tester) async {
    await pumpChat(tester, loaded: 30);
    unawaited(search.search('apple'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      unawaited(search.showOlder());
      await tester.pumpAndSettle();
    }
    expect(search.currentMessageId, idOf(150));
    // 170 is loaded; 160 is not, and loading around it also loads 150.
    expect(loadedAround, [idOf(160)]);
    expect(textOf('msg 150 apple'), findsOneWidget);

    await dispose(tester);
  });

  testWidgets('stepping quickly loads only the last requested result', (tester) async {
    await pumpChat(tester, loaded: 20, loadDelay: const Duration(milliseconds: 300));
    unawaited(search.search('apple'));
    await tester.pumpAndSettle();
    // 190 and 180 are loaded; 170 is not, and 150 is not loaded around it.
    unawaited(search.showOlder()); // 180, loaded
    await tester.pumpAndSettle();
    unawaited(search.showOlder()); // 170: starts loading
    await tester.pump();
    unawaited(search.showOlder()); // 160: waits
    unawaited(search.showOlder()); // 150: replaces 160
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }
    expect(loadedAround, [idOf(170), idOf(150)]);
    expect(search.currentMessageId, idOf(150));
    expect(textOf('msg 150 apple'), findsOneWidget);

    await dispose(tester);
  });

  testWidgets('keyboard shortcuts open, step through and close the search', (tester) async {
    await pumpChat(tester);
    // Nothing is focused: the shortcuts work while the chat is shown.
    expect(FocusManager.instance.primaryFocus?.context?.widget, isNot(isA<EditableText>()));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(search.isOpen, isTrue);
    final field = find.descendant(of: find.byType(ChatSearchBar), matching: find.byType(TextField));
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

    await tester.enterText(field, 'apple');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(search.index, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pumpAndSettle();
    expect(search.index, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(search.index, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(search.isOpen, isFalse);

    await dispose(tester);
  });

  testWidgets('searchShortcuts and searchBarBuilder replace the defaults', (tester) async {
    await pumpChat(
      tester,
      configuration: ChatConfiguration(
        searchShortcuts: const {
          SingleActivator(LogicalKeyboardKey.keyK, control: true): OpenChatSearchIntent(),
        },
        searchBarBuilder: (context, search) => Text('custom bar: ${search.query}'),
      ),
    );
    await tester.tap(find.byKey(const Key('input')));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(search.isOpen, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(search.isOpen, isTrue);
    expect(find.text('custom bar: '), findsOneWidget);
    expect(find.byType(ChatSearchBar), findsNothing);

    await dispose(tester);
  });
}
