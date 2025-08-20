import 'package:chat_toolkit/chat/message/entity/message.dart';

/// A group of consecutive messages from the same sender.
///
/// This class implements message grouping logic to create a natural
/// conversation flow by combining messages from the same sender that
/// are sent within a short time period. This follows the Aggregate
/// pattern from Domain-Driven Design.
///
/// Messages are grouped when they:
/// - Come from the same sender
/// - Are sent within the same minute
/// - Maintain chronological order
///
/// Example usage:
/// ```dart
/// final group = MessageGroup(
///   name: "John",
///   isSender: false,
///   timestamp: "2023-01-01T12:00:00Z",
///   messages: [message1, message2],
/// );
/// group.sortMessages(); // Ensures proper ordering
/// ```
class MessageGroup {
  /// List of messages in this group.
  ///
  /// Messages are automatically maintained in chronological order
  /// with failed messages sorted to the end.
  final List<Message> messages;

  /// Display name of the sender for this group.
  final String name;

  /// Whether this group contains messages from the sender.
  ///
  /// Used to determine UI alignment and styling.
  final bool isSender;

  /// Timestamp of the first message in this group.
  ///
  /// Used for date comparison and grouping logic.
  final String timestamp;

  MessageGroup({
    required this.messages,
    required this.name,
    required this.isSender,
    required this.timestamp,
  });

  /// Sorts messages in this group by timestamp and failure state.
  ///
  /// This method ensures proper message ordering:
  /// 1. Successful messages are sorted chronologically
  /// 2. Failed sender messages are moved to the end
  /// 3. Maintains consistent display order for better UX
  void sortMessages() {
    messages.sort((a, b) {
      if (a is SenderMessage && b is SenderMessage) {
        if (a.isFailed && !b.isFailed) return 1;
        if (!a.isFailed && b.isFailed) return -1;
      }
      final aTimestamp = DateTime.parse(a.timestamp);
      final bTimestamp = DateTime.parse(b.timestamp);
      if (aTimestamp.isBefore(bTimestamp)) return -1;
      if (aTimestamp.isAfter(bTimestamp)) return 1;
      return 0;
    });
  }
}
