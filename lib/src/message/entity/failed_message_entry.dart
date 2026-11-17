import '../../chat_controller.dart';
import 'message_group.dart';

/// Bookkeeping for a failed message that can be retried.
class FailedMessageEntry {
  /// Id of the failed message.
  final String messageId;

  /// Group that currently contains the failed message.
  final MessageGroup messageGroup;

  /// Callback used to send the message again.
  final MessageDispatchCallback onDispatch;

  /// Creates a [FailedMessageEntry].
  FailedMessageEntry({
    required this.messageId,
    required this.messageGroup,
    required this.onDispatch,
  });

  /// Returns a copy with the given fields replaced.
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
