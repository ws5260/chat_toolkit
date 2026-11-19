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
  String get previewText => text;

  @override
  _TextElement copyWith() => _TextElement(text);
}

void main() {
  final base = DateTime(2026, 3, 1, 9);
  String ts(int minutes) => base.add(Duration(minutes: minutes)).toIso8601String();

  Widget chat(ChatController c, {required bool notice}) => MaterialApp(
        home: Scaffold(
          body: Chat(
            chatController: c,
            configuration: ChatConfiguration(
              newReceiveMessageNotificationBuilder: notice
                  ? (context, message, controller) =>
                      Text('notice: ${message.name}: ${message.previewText}')
                  : null,
            ),
          ),
        ),
      );

  testWidgets('a notification builder set after the chat was built shows new messages',
      (tester) async {
    final c = ChatController()
      ..setMessages([
        for (var i = 0; i < 40; i++)
          ReceiverMessage(
            id: 'm$i',
            name: 'other',
            timestamp: ts(i),
            elements: [_TextElement('msg $i')],
          ),
      ]);
    addTearDown(c.dispose);

    // Built without a notice, then the notice is switched on (same Chat state).
    await tester.pumpWidget(chat(c, notice: false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(chat(c, notice: true));
    await tester.pumpAndSettle();

    c.jumpTo(1500); // scrolled up, away from the newest message
    await tester.pumpAndSettle();
    c.dispatchMessage(
      ReceiverMessage(
        id: 'new',
        name: 'Alex',
        timestamp: ts(100),
        elements: const [_TextElement('are you there?')],
      ),
      onDispatch: (m) async => m,
    );
    await tester.pumpAndSettle();

    expect(find.text('notice: Alex: are you there?'), findsOneWidget);
  });

  testWidgets('no notice without a builder', (tester) async {
    final c = ChatController()
      ..setMessages([
        for (var i = 0; i < 40; i++)
          ReceiverMessage(
              id: 'm$i', name: 'other', timestamp: ts(i), elements: [_TextElement('msg $i')]),
      ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(chat(c, notice: false));
    await tester.pumpAndSettle();
    c.jumpTo(1500);
    await tester.pumpAndSettle();
    final before = c.position.pixels;
    c.dispatchMessage(
      ReceiverMessage(
          id: 'new', name: 'Alex', timestamp: ts(100), elements: const [_TextElement('hi')]),
      onDispatch: (m) async => m,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('notice:'), findsNothing);
    expect(c.position.pixels, greaterThan(before - 100)); // not pulled to the newest
  });
}
