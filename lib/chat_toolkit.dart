/// A customizable chat UI toolkit for Flutter.
///
/// The main building blocks are:
///
/// * [Chat] – the scrollable chat widget that renders grouped message bubbles,
///   date separators, profiles and an optional input field.
/// * [ChatController] – holds the messages, sends them with
///   [ChatController.dispatchMessage], retries failed ones and controls scrolling.
/// * [MessageGroup] – a read-only run of consecutive messages from the same
///   sender, as exposed by [ChatController.messageGroups].
/// * [ChatConfiguration] and [BubbleConfiguration] – appearance and behavior options.
/// * [Message], [SenderMessage] and [ReceiverMessage] – message models, whose
///   content is made of [MessageElement]s you implement.
/// * [BubbleMenuConfiguration] and [BubbleMenuItem] – a long-press context menu
///   for bubbles.
///
/// A typical integration:
///
/// 1. Implement a [MessageElement] for each content type (text, image, ...).
/// 2. Create a [ChatController], load history with
///    [ChatController.setMessages], and dispose the controller with your
///    screen.
/// 3. Show it with [Chat], loading older pages from [Chat.onScrollToTop]
///    with [ChatController.appendMessages].
/// 4. Send messages from your input field with
///    [ChatController.dispatchMessage], and add messages pushed by your
///    server with [ChatController.addMessage].
///
/// The controller is the single source of truth: [ChatController.messageGroups]
/// and [MessageGroup.messages] are read-only live views, and every change
/// goes through the controller's methods.
///
/// ```dart
/// class TextElement extends MessageElement {
///   const TextElement(this.text);
///   final String text;
///
///   @override
///   Widget toWidget(BuildContext context) => Text(text);
///
///   @override
///   TextElement copyWith() => TextElement(text);
/// }
///
/// final controller = ChatController();
///
/// Chat(
///   chatController: controller,
///   customInputField: (context, controller) => MyInputField(
///     onSend: (text) => controller.dispatchMessage(
///       SenderMessage(
///         name: 'Me',
///         timestamp: DateTime.now().toIso8601String(),
///         elements: [TextElement(text)],
///       ),
///       onDispatch: api.send, // returns the stored message, or null on failure
///     ),
///   ),
/// );
/// ```
library;

export 'src/chat.dart';
export 'src/chat_configuration.dart';
// ChatControllerInternal is for Chat only.
export 'src/chat_controller.dart' hide ChatControllerInternal;
// showBubbleMenu and BubbleMenuDetector are used by the bubble widgets only.
export 'src/message/bubble_menu.dart' hide BubbleMenuConfigurationInternal, BubbleMenuDetector, showBubbleMenu;
export 'src/message/elements/message_element.dart';
export 'src/message/entity/message.dart';
// MessageGroupInternal is for ChatController only.
export 'src/message/entity/message_group.dart' hide MessageGroupInternal;
