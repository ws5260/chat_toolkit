import 'package:chat_toolkit/chat/chat_controller.dart';
import 'package:chat_toolkit/chat/message/entity/message_group.dart';

class FailedMessageEntry {
  final String messageId;
  final MessageGroup messageGroup;
  final MessageDispatchCallback onDispatch;

  FailedMessageEntry({
    required this.messageId,
    required this.messageGroup,
    required this.onDispatch,
  });

  FailedMessageEntry copyWith({
    MessageGroup? messageGroup,
    MessageDispatchCallback? onDispatch,
  }) {
    return FailedMessageEntry(
      messageId: messageId,
      messageGroup: messageGroup ?? this.messageGroup,
      onDispatch: onDispatch ?? this.onDispatch,
    );
  }

  @override
  String toString() {
    return 'FailedMessageEntry(messageId: $messageId, messageGroup: $messageGroup, onDispatch: $onDispatch)';
  }
}
