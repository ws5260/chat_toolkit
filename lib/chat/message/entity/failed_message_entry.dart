import 'package:chat_toolkit/chat/chat_controller.dart';
import 'package:chat_toolkit/chat/message/entity/message_group.dart';

/// Entry for tracking failed message dispatch operations.
///
/// This class maintains the state needed to retry failed messages,
/// following the Memento Pattern by storing the original dispatch
/// callback and group information for later retry attempts.
///
/// Used internally by [ChatController] to manage message failures
/// and provide retry functionality to users.
class FailedMessageEntry {
  /// The unique identifier of the failed message.
  final String messageId;

  /// The message group containing the failed message.
  ///
  /// This may change if messages are regrouped after retry attempts.
  final MessageGroup messageGroup;

  /// The original dispatch callback for retry operations.
  ///
  /// This callback will be invoked when the user attempts to retry
  /// sending the failed message.
  final MessageDispatchCallback onDispatch;

  FailedMessageEntry({
    required this.messageId,
    required this.messageGroup,
    required this.onDispatch,
  });

  /// Creates a copy of this entry with updated properties.
  ///
  /// Supports the Immutable Object pattern for safe state updates.
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
