import 'package:chat_toolkit/chat/message/entity/message.dart';

class MessageGroup {
  final List<Message> messages;
  final String name;
  final bool isSender;
  final String timestamp;

  MessageGroup({
    required this.messages,
    required this.name,
    required this.isSender,
    required this.timestamp,
  });

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
