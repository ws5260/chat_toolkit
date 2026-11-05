import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TextElement extends MessageElement {
  const _TextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) => Text(text);

  @override
  MessageElement copyWith() => _TextElement(text);
}

Widget _app(ChatController controller, BubbleMenuConfiguration? menu) {
  return MaterialApp(
    home: Scaffold(
      body: Chat(
        chatController: controller,
        configuration: ChatConfiguration(
          bubbleConfiguration: BubbleConfiguration(menuConfiguration: menu),
        ),
      ),
    ),
  );
}

ChatController _controllerWithBothSides() {
  final now = DateTime.now().toIso8601String();
  return ChatController()
    ..setMessages([
      ReceiverMessage(
        id: 'r1',
        name: 'Other',
        timestamp: now,
        elements: const [_TextElement('received')],
      ),
      SenderMessage(
        id: 's1',
        name: 'Me',
        timestamp: now,
        elements: const [_TextElement('sent')],
      ),
    ]);
}

void main() {
  testWidgets('long press opens a different menu per side', (tester) async {
    final controller = _controllerWithBothSides();
    addTearDown(controller.dispose);

    String? selected;
    final menu = BubbleMenuConfiguration(
      senderItemsBuilder: (context, request) => [
        BubbleMenuItem(
          label: 'Delete',
          onSelected: (_, request) => selected = 'delete:${request.message.id}',
        ),
        const BubbleMenuItem(label: 'Copy'),
      ],
      receiverItemsBuilder: (context, request) => [
        const BubbleMenuItem(label: 'Reply'),
        const BubbleMenuItem(label: 'Report'),
      ],
    );

    await tester.pumpWidget(_app(controller, menu));
    await tester.pumpAndSettle();

    // Receiver bubble.
    await tester.longPress(find.text('received'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);

    await tester.tapAt(const Offset(5, 5)); // dismiss
    await tester.pumpAndSettle();

    // Sender bubble.
    await tester.longPress(find.text('sent'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Reply'), findsNothing);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(selected, 'delete:s1');
  });

  testWidgets('right click does not open the menu', (tester) async {
    final controller = _controllerWithBothSides();
    addTearDown(controller.dispose);

    final menu = BubbleMenuConfiguration(
      receiverItemsBuilder: (context, request) => const [
        BubbleMenuItem(label: 'Reply'),
      ],
    );

    await tester.pumpWidget(_app(controller, menu));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('received')),
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsNothing);
  });

  testWidgets('enableLongPress: false disables the menu', (tester) async {
    final controller = _controllerWithBothSides();
    addTearDown(controller.dispose);

    final menu = BubbleMenuConfiguration(
      enableLongPress: false,
      receiverItemsBuilder: (context, request) => const [
        BubbleMenuItem(label: 'Reply'),
      ],
    );

    await tester.pumpWidget(_app(controller, menu));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('received'));
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsNothing);
  });

  testWidgets('a side without a builder has no menu', (tester) async {
    final controller = _controllerWithBothSides();
    addTearDown(controller.dispose);

    final menu = BubbleMenuConfiguration(
      receiverItemsBuilder: (context, request) => const [
        BubbleMenuItem(label: 'Reply'),
      ],
    );

    await tester.pumpWidget(_app(controller, menu));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('sent'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsNothing);
  });

  testWidgets('an empty item list suppresses the menu', (tester) async {
    final controller = _controllerWithBothSides();
    addTearDown(controller.dispose);

    final menu = BubbleMenuConfiguration(
      receiverItemsBuilder: (context, request) => const <BubbleMenuItem>[],
    );

    await tester.pumpWidget(_app(controller, menu));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('received'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<int>), findsNothing);
  });

  testWidgets('animationStyle retimes the menu transition', (tester) async {
    final controller = _controllerWithBothSides();
    addTearDown(controller.dispose);

    final menu = BubbleMenuConfiguration(
      animationStyle: AnimationStyle.noAnimation,
      receiverItemsBuilder: (context, request) => const [
        BubbleMenuItem(label: 'Reply'),
      ],
    );

    await tester.pumpWidget(_app(controller, menu));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('received'));
    await tester.pump(); // no transition to settle

    expect(find.text('Reply'), findsOneWidget);
  });

  testWidgets('a custom handler replaces the default menu', (tester) async {
    final controller = _controllerWithBothSides();
    addTearDown(controller.dispose);

    BubbleMenuRequest? captured;
    final menu = BubbleMenuConfiguration(
      receiverItemsBuilder: (context, request) => const [
        BubbleMenuItem(label: 'Reply'),
      ],
      receiverMenuHandler: (context, request) async {
        captured = request;
      },
    );

    await tester.pumpWidget(_app(controller, menu));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('received'));
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsNothing);
    expect(captured?.message.id, 'r1');
    expect(captured?.isSender, isFalse);
    expect(captured?.bubbleRect.isEmpty, isFalse);
  });
}
