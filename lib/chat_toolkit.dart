/// A comprehensive Flutter chat toolkit that provides customizable chat widgets
/// and controllers for building chat interfaces.
///
/// This library follows Clean Architecture principles and SOLID design patterns
/// to ensure maintainable and extensible chat functionality.
///
/// Example usage:
/// ```dart
/// Chat(
///   chatController: ChatController(),
///   configuration: ChatConfiguration(
///     senderAlignment: ChatAlignment.end,
///   ),
/// )
/// ```
library chat_toolkit;

export 'chat/chat.dart';
export 'chat/chat_configuration.dart';
export 'chat/chat_controller.dart';
export 'chat/message/entity/message.dart';
export 'chat/message/entity/message_group.dart';
export 'chat/message/message_bubble.dart';
