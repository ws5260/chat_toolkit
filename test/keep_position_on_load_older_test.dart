import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<ChatController> pumpChat(WidgetTester tester) async {
    final c = ChatController()
      ..setMessages([for (var i = 0; i < 40; i++) message(i)]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Chat(chatController: c)),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  // Older page, newest first (as appendMessages expects).
  List<Message> olderPage() => [for (var i = -1; i >= -30; i--) message(i)];

  Future<void> expectStaysInPlace(
    WidgetTester tester,
    ChatController c,
    String label,
  ) async {
    final before = tester.getTopLeft(find.text(label)).dy;
    c.appendMessages(olderPage());
    await tester.pump();
    expect(find.text(label), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(label)).dy,
      moreOrLessEquals(before, epsilon: 1),
    );
  }

  testWidgets('at the oldest end: visible messages stay in place', (
    tester,
  ) async {
    final c = await pumpChat(tester);
    c.jumpTo(c.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await expectStaysInPlace(tester, c, 'msg 2');

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('in the middle: visible messages stay in place', (tester) async {
    final c = await pumpChat(tester);
    c.jumpTo(c.position.maxScrollExtent / 2);
    await tester.pumpAndSettle();
    final label = find
        .textContaining('msg ')
        .evaluate()
        .map((e) => (e.widget as Text).data!)
        .elementAt(3);
    await expectStaysInPlace(tester, c, label);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
