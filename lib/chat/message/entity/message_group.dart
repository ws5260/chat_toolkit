import 'message.dart';

/// Consecutive messages from the same author, shown under one profile.
///
/// By default, messages are grouped when they are on the same side, have the
/// same [Message.name] and were sent within the same minute.
class MessageGroup {
  /// Messages in this group, oldest first.
  final List<Message> messages;

  /// Author name shared by the messages.
  final String name;

  /// Whether the messages are sender messages.
  final bool isSender;

  /// Timestamp of the message that started the group.
  final String timestamp;

  /// Creates a [MessageGroup].
  MessageGroup({
    required this.messages,
    required this.name,
    required this.isSender,
    required this.timestamp,
  });

  /// Sorts [messages] by timestamp, placing failed and then loading sender
  /// messages last.
  void sortMessages() {
    messages.sort((a, b) {
      if (a is SenderMessage && b is SenderMessage) {
        if (a.isFailed && !b.isFailed) return 1;
        if (!a.isFailed && b.isFailed) return -1;
        if (a.isLoading && !b.isLoading) return 1;
        if (!a.isLoading && b.isLoading) return -1;
      }

      final aTimestamp = DateTime.parse(a.timestamp);
      final bTimestamp = DateTime.parse(b.timestamp);
      if (aTimestamp.isBefore(bTimestamp)) return -1;
      if (aTimestamp.isAfter(bTimestamp)) return 1;
      return 0;
    });
  }
}
