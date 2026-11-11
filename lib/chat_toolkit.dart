/// A customizable chat UI toolkit for Flutter.
///
/// The main building blocks are:
///
/// * [Chat] – the scrollable chat widget that renders grouped message bubbles,
///   date separators, profiles and an optional input field.
/// * [ChatController] – holds the messages, sends them with
///   [ChatController.dispatchMessage], retries failed ones and controls scrolling.
/// * [ChatConfiguration] and [BubbleConfiguration] – appearance and behavior options.
/// * [Message], [SenderMessage] and [ReceiverMessage] – message models, whose
///   content is made of [MessageElement]s you implement.
/// * [BubbleMenuConfiguration] – a long-press context menu for bubbles.
///
/// ```dart
/// final controller = ChatController();
///
/// Chat(
///   chatController: controller,
///   customInputField: (context, controller) => MyInputField(controller),
/// );
/// ```
library;

export 'chat/chat.dart';
export 'chat/chat_configuration.dart';
export 'chat/chat_controller.dart';
export 'chat/message/bubble_menu.dart';
export 'chat/message/elements/message_element.dart';
export 'chat/message/entity/message.dart';
export 'chat/message/message_bubble.dart';
