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

void main() {
  final base = DateTime(2026, 3, 1, 9);
  String ts(int minutes) =>
      base.add(Duration(minutes: minutes)).toIso8601String();

  for (final animation in [null, const Duration(milliseconds: 250)]) {
    testWidgets('animation: ${animation != null}: '
        'sending while scrolled up scrolls down before the server responds', (
      tester,
    ) async {
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
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Chat(
              chatController: c,
              configuration: ChatConfiguration(
                messageAppearAnimationDuration: animation,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      c.scrollToBottom();
      await tester.pumpAndSettle();
      // Scroll well up, toward older messages.
      c.jumpTo(1500);
      await tester.pumpAndSettle();

      double gap() => c.position.pixels;

      final future = c.dispatchMessage(
        SenderMessage(
          id: 'sent',
          name: 'me',
          timestamp: ts(100),
          elements: const [_TextElement('hi')],
        ),
        onDispatch: (m) async {
          await Future<void>.delayed(const Duration(seconds: 2)); // slow server
          return m.copyWith(isLoading: false);
        },
      );

      // Well before the server responds.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // (The bubble shows the loading indicator until the server responds.)
      expect(gap(), lessThanOrEqualTo(2));

      await tester.pump(const Duration(seconds: 2));
      await future;
      await tester.pumpAndSettle();
      expect(find.text('hi'), findsOneWidget);
      expect(gap(), lessThanOrEqualTo(2));

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
