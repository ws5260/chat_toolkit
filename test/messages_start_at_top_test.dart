import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TextElement extends MessageElement {
  const _TextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(8), child: Text(text));

  @override
  _TextElement copyWith() => _TextElement(text);
}

void main() {
  final base = DateTime(2026, 3, 1, 9);
  Message message(int i) => ReceiverMessage(
      id: 'm$i',
      name: 'other',
      timestamp: base.add(Duration(minutes: i)).toIso8601String(),
      elements: [_TextElement('msg $i')]);

  // Test surface is 800x600.
  Future<ChatController> pumpChat(WidgetTester tester,
      {required bool reverse,
      required bool startAtTop,
      required int count,
      Duration? animation}) async {
    final c = ChatController(reverse: reverse)
      ..setMessages([for (var i = 0; i < count; i++) message(i)]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Chat(
          key: ObjectKey(c), // a new Chat for each controller
          chatController: c,
          configuration: ChatConfiguration(
            messagesStartAtTop: startAtTop,
            messageAppearAnimationDuration: animation,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return c;
  }

  double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

  testWidgets('reversed, short: messages start at the top', (tester) async {
    final c = await pumpChat(tester, reverse: true, startAtTop: true, count: 3);
    expect(top(tester, 'msg 0'), lessThan(150));
    // Oldest first, top to bottom.
    expect(top(tester, 'msg 0'), lessThan(top(tester, 'msg 1')));
    expect(top(tester, 'msg 1'), lessThan(top(tester, 'msg 2')));
    // Cannot scroll: the list does not fill the screen.
    expect(c.position.maxScrollExtent, 0);
    c.dispose();
  });

  testWidgets('reversed, short, option off: messages stay at the bottom (unchanged)',
      (tester) async {
    final c = await pumpChat(tester, reverse: true, startAtTop: false, count: 3);
    expect(top(tester, 'msg 2'), greaterThan(400));
    c.dispose();
  });

  testWidgets('not reversed: the option changes nothing', (tester) async {
    final on = await pumpChat(tester, reverse: false, startAtTop: true, count: 3);
    final withOption = top(tester, 'msg 0');
    on.dispose();
    final off = await pumpChat(tester, reverse: false, startAtTop: false, count: 3);
    expect(top(tester, 'msg 0'), withOption);
    off.dispose();
  });

  testWidgets('reversed, long: unchanged, newest at the bottom', (tester) async {
    final on = await pumpChat(tester, reverse: true, startAtTop: true, count: 40);
    final newestWithOption = top(tester, 'msg 39');
    final maxWithOption = on.position.maxScrollExtent;
    on.dispose();
    final off = await pumpChat(tester, reverse: true, startAtTop: false, count: 40);
    expect(top(tester, 'msg 39'), newestWithOption);
    expect(off.position.maxScrollExtent, maxWithOption);
    expect(newestWithOption, greaterThan(400));
    off.dispose();
  });

  for (final animation in [null, const Duration(milliseconds: 250)]) {
    testWidgets(
        'reversed, short: new messages are added below, until the screen is full '
        '(animation: ${animation != null})', (tester) async {
      final c = await pumpChat(tester,
          reverse: true, startAtTop: true, count: 2, animation: animation);
      final firstTop = top(tester, 'msg 0');

      c.addMessage(message(2));
      await tester.pumpAndSettle();
      expect(top(tester, 'msg 0'), firstTop, reason: 'existing messages do not move');
      expect(top(tester, 'msg 2'), greaterThan(top(tester, 'msg 1')));

      // Fill the screen: from then on the newest message is at the bottom as usual.
      for (var i = 3; i < 40; i++) {
        c.addMessage(message(i));
      }
      await tester.pumpAndSettle();
      expect(c.position.maxScrollExtent, greaterThan(0));
      expect(top(tester, 'msg 39'), greaterThan(400));
      c.dispose();
    });
  }

  testWidgets('reversed, short: bubbles can still be tapped where they are drawn',
      (tester) async {
    final c = await pumpChat(tester, reverse: true, startAtTop: true, count: 3);
    expect(find.text('msg 0').hitTestable(), findsOneWidget);
    c.dispose();
  });
}
