import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _TextElement extends MessageElement {
  const _TextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(8), child: Text(text));

  @override
  _TextElement copyWith() => _TextElement(text);
}

// An item in the middle of its entrance animation (height not yet full).
final _animating = find.byWidgetPredicate(
  (w) => w is Align && w.heightFactor != null && w.heightFactor! < 1,
);

void main() {
  final base = DateTime(2026, 3, 1, 9);
  String ts(int minutes) =>
      base.add(Duration(minutes: minutes)).toIso8601String();

  ReceiverMessage received(String id, int minute) => ReceiverMessage(
    id: id,
    name: 'other',
    timestamp: ts(minute),
    elements: [_TextElement(id)],
  );

  Future<ChatController> pumpChat(
    WidgetTester tester, {
    Duration? duration = const Duration(milliseconds: 250),
  }) async {
    final c = ChatController()
      ..setMessages([for (var i = 0; i < 40; i++) received('m$i', i)]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Chat(
            chatController: c,
            configuration: ChatConfiguration(
              messageAppearAnimationDuration: duration,
            ),
          ),
        ),
      ),
    );
    // Loaded history does not animate.
    expect(_animating, findsNothing);
    await tester.pumpAndSettle();
    c.scrollToBottom();
    await tester.pumpAndSettle();
    return c;
  }

  double gap(ChatController c) => c.position.pixels;

  testWidgets('a new message animates in, then settles at full size', (
    tester,
  ) async {
    final c = await pumpChat(tester);
    c.addMessage(received('new', 100)); // new group
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_animating, findsOneWidget);

    await tester.pumpAndSettle();
    expect(_animating, findsNothing);
    expect(find.text('new'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('a message joining an existing group animates its bubble', (
    tester,
  ) async {
    final c = await pumpChat(tester);
    // Same sender and minute as the last loaded message: joins its group.
    c.addMessage(
      ReceiverMessage(
        id: 'join',
        name: 'other',
        timestamp: base
            .add(const Duration(minutes: 39, seconds: 30))
            .toIso8601String(),
        elements: const [_TextElement('join')],
      ),
    );
    expect(c.messageGroups.last.messages.length, 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_animating, findsOneWidget);
    await tester.pumpAndSettle();
    expect(_animating, findsNothing);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('sending keeps the list at the bottom while it animates', (
    tester,
  ) async {
    final c = await pumpChat(tester);
    await c.dispatchMessage(
      SenderMessage(
        id: 's1',
        name: 'me',
        timestamp: ts(100),
        elements: const [_TextElement('hi')],
      ),
      onDispatch: (m) async => m.copyWith(isLoading: false),
    );
    await tester.pumpAndSettle();
    expect(gap(c), lessThanOrEqualTo(2));

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('plays once: not again when scrolled back into view', (
    tester,
  ) async {
    final c = await pumpChat(tester);
    c.addMessage(received('new', 100));
    await tester.pumpAndSettle();

    // Scroll far away so the item is disposed, then come back.
    c.jumpTo(c.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('new'), findsNothing);
    c.scrollToBottom();
    await tester.pump();
    expect(find.text('new'), findsOneWidget);
    expect(_animating, findsNothing);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('disabled by default', (tester) async {
    final c = await pumpChat(tester, duration: null);
    c.addMessage(received('new', 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_animating, findsNothing);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
