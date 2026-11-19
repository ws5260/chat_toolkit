import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _TextElement extends MessageElement {
  const _TextElement(this.text);
  final String text;

  // Varying heights, like real messages.
  @override
  Widget toWidget(BuildContext context) =>
      SizedBox(height: 30.0 + (text.hashCode % 5) * 25, child: Text(text));

  @override
  _TextElement copyWith() => _TextElement(text);
}

void main() {
  final base = DateTime(2026, 3, 1, 9);
  Message message(int i) => ReceiverMessage(
    id: 'm${(i + 1000).toString().padLeft(6, '0')}',
    name: 'other',
    timestamp: base.add(Duration(minutes: 7 * i)).toIso8601String(),
    elements: [_TextElement('msg $i')],
  );
  String idOf(int i) => message(i).id;
  List<Message> range(int from, int to) => [for (var i = from; i < to; i++) message(i)];

  late int bottomCalls;
  late int topCalls;

  Future<ChatController> pumpChat(
    WidgetTester tester, {
    ChatConfiguration configuration = const ChatConfiguration(),
  }) async {
    bottomCalls = 0;
    topCalls = 0;
    final c = ChatController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Chat(
            chatController: c,
            configuration: configuration,
            onScrollToTop: () async => topCalls++,
            onScrollToBottom: () async => bottomCalls++,
          ),
        ),
      ),
    );
    return c;
  }

  Future<bool> settle<T>(WidgetTester tester, Future<bool> future) async {
    await tester.pumpAndSettle();
    return future;
  }

  double centerOf(WidgetTester tester, String label) => tester.getCenter(find.text(label)).dy;
  const viewportCenter = 600 / 2;

  testWidgets('scrollToMessage reveals a loaded message far from the bottom', (tester) async {
    final c = await pumpChat(tester);
    c.setMessages(range(0, 200));
    await tester.pumpAndSettle();
    expect(find.text('msg 20'), findsNothing);

    expect(await settle(tester, c.scrollToMessage(idOf(20))), isTrue);
    expect(find.text('msg 20'), findsOneWidget);
    expect(centerOf(tester, 'msg 20'), moreOrLessEquals(viewportCenter, epsilon: 60));

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('scrollToMessage centers a message at the oldest loaded edge once older ones load', (
    tester,
  ) async {
    final c = await pumpChat(tester);
    c.setMessages(range(100, 130));
    await tester.pumpAndSettle();

    // Nothing older is loaded yet, so the list cannot scroll far enough to center msg 100.
    expect(await settle(tester, c.scrollToMessage(idOf(100))), isTrue);
    expect(centerOf(tester, 'msg 100'), lessThan(viewportCenter - 20));

    // Once older messages arrive, it is centered.
    c.appendMessages([for (var i = 99; i >= 70; i--) message(i)]);
    await tester.pumpAndSettle();
    expect(centerOf(tester, 'msg 100'), moreOrLessEquals(viewportCenter, epsilon: 10));

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('scrollToMessage returns false for a message that is not loaded', (tester) async {
    final c = await pumpChat(tester);
    c.setMessages(range(0, 50));
    await tester.pumpAndSettle();
    expect(await settle(tester, c.scrollToMessage('missing')), isFalse);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('setMessagesAround shows and highlights the anchor', (tester) async {
    final c = await pumpChat(
      tester,
      configuration: ChatConfiguration(
        messageHighlightBuilder: (context, child, animation) =>
            KeyedSubtree(key: const ValueKey('highlight'), child: child),
      ),
    );
    c.setMessages(range(470, 500));
    await tester.pumpAndSettle();

    final shown = c.setMessagesAround(range(70, 130), anchorMessageId: idOf(100));
    // The very first frame already shows the anchor's group in the middle.
    await tester.pump();
    expect(find.text('msg 100'), findsOneWidget);
    expect(await settle(tester, shown), isTrue);
    // Then the message itself is centered, even when it is not the first of its group.
    expect(centerOf(tester, 'msg 100'), moreOrLessEquals(viewportCenter, epsilon: 10));
    expect(c.hasNewerMessages, isTrue);
    final highlight = find.byKey(const ValueKey('highlight'));
    expect(highlight, findsOneWidget);
    expect(find.descendant(of: highlight, matching: find.text('msg 100')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('loading newer and older pages keeps the visible messages in place', (
    tester,
  ) async {
    final c = await pumpChat(tester);
    await settle(tester, c.setMessagesAround(range(70, 130), anchorMessageId: idOf(100)));

    var before = centerOf(tester, 'msg 100');
    c.addNewerMessages(range(130, 160));
    await tester.pump();
    expect(centerOf(tester, 'msg 100'), moreOrLessEquals(before, epsilon: 1));

    before = centerOf(tester, 'msg 100');
    c.appendMessages([for (var i = 69; i >= 40; i--) message(i)]);
    await tester.pump();
    expect(centerOf(tester, 'msg 100'), moreOrLessEquals(before, epsilon: 1));

    // At the newest loaded end too.
    c.scrollToBottom();
    await tester.pumpAndSettle();
    expect(find.text('msg 159'), findsOneWidget);
    before = centerOf(tester, 'msg 159');
    c.addNewerMessages(range(160, 190), hasMore: false);
    await tester.pump();
    expect(centerOf(tester, 'msg 159'), moreOrLessEquals(before, epsilon: 1));
    expect(c.hasNewerMessages, isFalse);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('onScrollToBottom is called at the newest loaded end only while newer exist', (
    tester,
  ) async {
    final c = await pumpChat(tester);
    c.setMessages(range(0, 100));
    await tester.pumpAndSettle();
    expect(bottomCalls, 0);

    await settle(tester, c.setMessagesAround(range(0, 100), anchorMessageId: idOf(30)));
    final callsAfterJump = bottomCalls;
    c.scrollToBottom();
    await tester.pumpAndSettle();
    expect(bottomCalls, greaterThan(callsAfterJump));

    c.addNewerMessages(const [], hasMore: false);
    await tester.pumpAndSettle();
    final callsWhenCaughtUp = bottomCalls;
    c.jumpTo(c.position.pixels + 50);
    await tester.pumpAndSettle();
    c.scrollToBottom();
    await tester.pumpAndSettle();
    expect(bottomCalls, callsWhenCaughtUp);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('when caught up, a new message at the bottom is followed', (tester) async {
    final c = await pumpChat(tester);
    await settle(
      tester,
      c.setMessagesAround(range(70, 130), anchorMessageId: idOf(100), hasNewerMessages: true),
    );
    c.addNewerMessages(range(130, 140), hasMore: false);
    c.scrollToBottom();
    await tester.pumpAndSettle();

    c.addMessage(message(140));
    await tester.pumpAndSettle();
    expect(find.text('msg 140'), findsOneWidget);
    expect(c.isAtBottom(), isTrue);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('setMessages returns to the latest messages', (tester) async {
    final c = await pumpChat(tester);
    await settle(tester, c.setMessagesAround(range(70, 130), anchorMessageId: idOf(100)));

    c.setMessages(range(470, 500));
    await tester.pumpAndSettle();
    expect(c.hasNewerMessages, isFalse);
    expect(find.text('msg 499'), findsOneWidget);
    expect(c.position.pixels, 0);
    expect(c.position.minScrollExtent, 0);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('scrollToMessage draws the final position in the next frame', (tester) async {
    final c = await pumpChat(tester);
    c.setMessages(range(0, 200));
    await tester.pumpAndSettle();

    final shown = c.scrollToMessage(idOf(20));
    await tester.pump(); // the frame that waits for the layout
    await tester.pump(); // the first frame after the jump
    expect(find.text('msg 20'), findsOneWidget);
    final firstFrame = centerOf(tester, 'msg 20');
    expect(firstFrame, moreOrLessEquals(viewportCenter, epsilon: 1));
    expect(await settle(tester, shown), isTrue);
    expect(centerOf(tester, 'msg 20'), firstFrame);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
