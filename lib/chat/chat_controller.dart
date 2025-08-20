import 'dart:async';

import 'package:chat_toolkit/chat/message/entity/message.dart';
import 'package:flutter/material.dart';

/// Callback function type for message dispatch operations.
///
/// Takes a [Message] and returns a [Future] that resolves to the processed
/// message or null if the operation failed.
typedef MessageDispatchCallback = Future<Message?> Function(Message);

/// Result of a message dispatch operation.
///
/// Contains information about the success status and any exceptions
/// that occurred during the dispatch process.
class MessageDispatchResult {
  /// The original message that was dispatched.
  final Message message;

  /// Whether the dispatch operation was successful.
  final bool isSuccess;

  /// Exception that occurred during dispatch, if any.
  final Exception? exception;

  MessageDispatchResult(
      {required this.message, required this.isSuccess, this.exception});
}

/// Controller that manages chat state and behavior.
///
/// This controller extends [ScrollController] to provide scrolling functionality
/// while also managing message state, dispatch operations, and failed message
/// handling. It follows the Single Responsibility Principle by focusing on
/// chat-specific state management.
///
/// Key responsibilities:
/// - Message state management
/// - Scroll behavior control
/// - Message dispatch and retry logic
/// - Failed message tracking
/// - Stream-based event notifications
///
/// Example usage:
/// ```dart
/// final controller = ChatController();
/// controller.addMessage(message);
/// controller.dispatchMessage(
///   message,
///   onDispatch: (msg) async {
///     // Send message to server
///     return processedMessage;
///   },
/// );
/// ```
class ChatController extends ScrollController {
  final StreamController<MessageDispatchResult> _dispatchResultController =
      StreamController.broadcast();
  final StreamController<Message> _newReceiveMessageController =
      StreamController.broadcast();

  /// Stream of message dispatch results.
  ///
  /// Emits [MessageDispatchResult] objects when messages are dispatched,
  /// allowing listeners to handle success/failure states.
  Stream<MessageDispatchResult> get dispatchResultStream =>
      _dispatchResultController.stream;

  /// Stream of newly received messages.
  ///
  /// Emits [Message] objects when new messages are received (not sent),
  /// useful for triggering notifications or scroll behavior.
  Stream<Message> get newReceiveMessageStream =>
      _newReceiveMessageController.stream;

  final List<MessageGroup> _messageGroups = [];

  /// List of message groups organized by sender and time.
  ///
  /// Messages are automatically grouped by sender and timestamp proximity
  /// to create a natural conversation flow.
  List<MessageGroup> get messageGroups => _messageGroups;

  final Map<String, FailedMessageEntry> _failedMessageEntries = {};

  bool _isCollapsed = false;

  /// Whether the chat is currently in collapsed state.
  bool get isCollapsed => _isCollapsed;

  bool _isDisposed = false;

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Sets the collapsed state of the chat.
  ///
  /// This method follows the Open/Closed Principle by allowing
  /// external control of the chat's visual state.
  setIsCollapsed(bool value) {
    _isCollapsed = value;
    notifyListeners();
  }

  /// Initializes the chat with a list of messages.
  ///
  /// This method replaces all existing messages and re-groups them
  /// based on sender and timestamp. Messages are automatically sorted
  /// chronologically.
  void setMessages(List<Message> messages) {
    _messageGroups.clear();
    messages.sort((a, b) {
      final aDate = DateTime.tryParse(a.timestamp);
      final bDate = DateTime.tryParse(b.timestamp);
      if (aDate == null || bDate == null) return 0;
      if (aDate.isBefore(bDate)) return -1;
      return 1;
    });
    for (final message in messages) {
      addMessage(message);
    }
  }

  /// Appends older messages to the beginning of the chat.
  ///
  /// This method is typically used for pagination when loading
  /// historical messages. Messages are inserted at the top while
  /// maintaining proper grouping.
  void appendMessages(List<Message> messages) {
    for (final message in messages) {
      if (_messageGroups.first.isSender == message.isSender &&
          isSameMinute(DateTime.parse(_messageGroups.first.timestamp),
              DateTime.parse(message.timestamp))) {
        _messageGroups.first.messages.insert(0, message);
      } else {
        _messageGroups.insert(
            0,
            MessageGroup(
              name: message.name,
              isSender: message.isSender,
              timestamp: message.timestamp,
              messages: [message],
            ));
      }
    }
    notifyListeners();
  }

  /// Creates a new ChatController.
  ///
  ChatController();

  @override
  void dispose() {
    _isDisposed = true;
    _messageGroups.clear();
    _dispatchResultController.close();
    _newReceiveMessageController.close();
    super.dispose();
  }

  /// Smoothly scrolls to the bottom of the chat.
  ///
  /// It performs an initial jump followed by a smooth animation
  /// for better user experience.
  void scrollToBottom() async {
    if (hasClients) {
      double movePosition = 0.0;
      jumpTo(movePosition);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        movePosition = 0.0;
        animateTo(
          movePosition,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void scrollToTopByValue(double offset) {
    if (hasClients) {
      final currentOffset = position.pixels;
      if (currentOffset < 10) return;
      jumpTo(
        currentOffset + offset,
      );
    }
  }

  void scrollToBottomByValue(double offset) {
    if (hasClients) {
      final currentOffset = position.pixels;
      if (currentOffset <= 0) return;
      if (currentOffset >= position.maxScrollExtent) return;
      jumpTo(
        currentOffset - offset,
      );
    }
  }

  /// Adds a message to the chat.
  ///
  /// Messages are automatically grouped with other messages from the same
  /// sender if they are sent within the same minute. This follows the
  /// Single Responsibility Principle by handling both message addition
  /// and grouping logic.
  ///
  /// Returns the [MessageGroup] that contains the added message.
  MessageGroup addMessage(Message message) {
    // _messages.add(message);
    // _messages.sort((a, b) {
    //   if (a.isFailed == b.isFailed) return 0;
    //   if (a.isFailed) return 1;
    //   return -1;
    // });
    late final MessageGroup messageGroup;
    if (_messageGroups.isEmpty ||
        _messageGroups.last.isSender != message.isSender ||
        !isSameMinute(DateTime.parse(_messageGroups.last.timestamp),
            DateTime.parse(message.timestamp))) {
      messageGroup = MessageGroup(
        name: message.name,
        isSender: message.isSender,
        timestamp: message.timestamp,
        messages: [message],
      );
      _messageGroups.add(messageGroup);
    } else {
      messageGroup = _messageGroups.last;
      messageGroup.messages.add(message);
    }

    if (_failedMessageEntries.containsKey(message.id)) {
      _failedMessageEntries[message.id] =
          _failedMessageEntries[message.id]!.copyWith(
        messageGroup: messageGroup,
      );
    }

    if (_failedMessageEntries.isNotEmpty) {
      final failedIds = List<String>.from(_failedMessageEntries.keys);

      for (final failedId in failedIds) {
        final entry = _failedMessageEntries[failedId]!;
        final failedMessage =
            entry.messageGroup.messages.firstWhere((m) => m.id == failedId);

        entry.messageGroup.messages.remove(failedMessage);
        if (entry.messageGroup.messages.isEmpty) {
          _messageGroups.remove(entry.messageGroup);
        }
        late final MessageGroup newGroup;
        if (_messageGroups.isNotEmpty &&
            _messageGroups.last.isSender == failedMessage.isSender) {
          newGroup = _messageGroups.last;
          newGroup.messages.add(failedMessage);
        } else {
          newGroup = MessageGroup(
            name: failedMessage.name,
            isSender: failedMessage.isSender,
            timestamp: failedMessage.timestamp,
            messages: [failedMessage],
          );
          _messageGroups.add(newGroup);
        }
        _failedMessageEntries[failedId] = entry.copyWith(
          messageGroup: newGroup,
        );
      }
    }
    notifyListeners();
    return messageGroup;
  }

  /// Dispatches a message through the provided callback.
  ///
  /// This method handles the complete message lifecycle:
  /// 1. Adds the message with loading state
  /// 2. Calls the dispatch callback
  /// 3. Updates the message based on the result
  /// 4. Handles failures and retry logic
  ///
  /// The [onDispatch] callback should return the processed message
  /// or null if the operation failed.
  ///
  /// Returns a [MessageDispatchResult] indicating success or failure.
  Future<MessageDispatchResult> dispatchMessage(
    Message message, {
    required MessageDispatchCallback onDispatch,
  }) async {
    final messageGroup =
        addMessage(message.copyWith(isLoading: true, isFailed: false));
    late final MessageDispatchResult dispatchResult;
    late final Message? result;

    result = await onDispatch(message);
    final index =
        messageGroup.messages.indexWhere((element) => element.id == message.id);
    if (result != null) {
      messageGroup.messages[index] = result;
      messageGroup.sortMessages();
      dispatchResult = MessageDispatchResult(
        message: message,
        isSuccess: true,
        exception: null,
      );
      if (!result.isSender) {
        _newReceiveMessageController.add(result);
      }

      notifyListeners();
    } else {
      dispatchResult = MessageDispatchResult(
        message: message,
        isSuccess: false,
        exception: Exception("Failed to dispatch message"),
      );
      removeMessageGroupAt(messageGroup, index);

      _failedMessageEntries[message.id] = FailedMessageEntry(
        messageId: message.id,
        messageGroup: messageGroup,
        onDispatch: onDispatch,
      );

      addMessage(message.copyWith(isLoading: false, isFailed: true));
    }
    if (_dispatchResultController.isClosed) return dispatchResult;
    _dispatchResultController.add(dispatchResult);

    return dispatchResult;
  }

  /// Retries a failed message.
  ///
  /// This method attempts to re-dispatch a message that previously failed.
  /// It removes the failed message from the UI and attempts dispatch again
  /// using the original dispatch callback.
  Future retryMessage(Message message) async {
    final entry = _failedMessageEntries[message.id];
    if (entry == null) {
      _dispatchResultController.add(MessageDispatchResult(
        message: message,
        isSuccess: false,
        exception: Exception("Failed to dispatch message"),
      ));
      return;
    }
    final failedGroup = entry.messageGroup;

    if (failedGroup.messages.isEmpty) {
      _dispatchResultController.add(MessageDispatchResult(
        message: message,
        isSuccess: false,
        exception: Exception("Failed to dispatch message"),
      ));
      return;
    }
    removeMessageFromGroup(failedGroup, message);

    await dispatchMessage(message, onDispatch: entry.onDispatch).then((result) {
      if (result.isSuccess) {
        _failedMessageEntries.remove(message.id);
      }
    });
  }

  /// Removes a message from all groups and cleans up empty groups.
  ///
  /// This method ensures data consistency by removing the message
  /// from all possible locations and cleaning up any empty groups
  /// that result from the removal.
  void removeMessageEverywhere(Message message) {
    for (final group in _messageGroups.toList()) {
      group.messages.removeWhere((m) => m.id == message.id);
    }
    _messageGroups.removeWhere((group) => group.messages.isEmpty);
    _failedMessageEntries.remove(message.id);

    notifyListeners();
  }

  void removeMessageFromGroup(MessageGroup group, Message message) {
    group.messages.remove(message);
    if (group.messages.isEmpty) {
      _messageGroups.remove(group);
    }
    _failedMessageEntries.remove(message.id);

    notifyListeners();
  }

  void removeMessageGroupAt(MessageGroup group, int messageIndex) {
    final message = group.messages.removeAt(messageIndex);
    if (group.messages.isEmpty) {
      _messageGroups.remove(group);
    }
    _failedMessageEntries.remove(message.id);

    notifyListeners();
  }

  bool isDateChangedComparedTo(Message message, Message other) {
    final thisDate = DateTime.tryParse(message.timestamp);
    final otherDate = DateTime.tryParse(other.timestamp);
    if (thisDate == null || otherDate == null) {
      return false;
    }
    return thisDate.day != otherDate.day ||
        thisDate.month != otherDate.month ||
        thisDate.year != otherDate.year;
  }

  bool isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  /// Checks if the scroll position is at the bottom within a threshold.
  ///
  /// Returns true if the user is close enough to the bottom to trigger
  /// auto-scroll or other bottom-related behaviors.
  ///
  /// The [threshold] parameter defines how close to the bottom
  /// the position needs to be (in pixels).
  bool isAtBottom({double threshold = 20}) {
    if (!hasClients) return true;
    return position.pixels <= threshold;
  }

  bool containsMessageId(String messageId) {
    for (final group in _messageGroups) {
      if (group.messages.any((m) => m.id == messageId)) {
        return true;
      }
    }
    return false;
  }
}

// class ChatControllerInhertedWidget extends InheritedWidget {
//   const ChatControllerInhertedWidget(
//       {super.key, required super.child, required this.controller});
//   final ChatController controller;

//   static ChatController of(BuildContext context) {
//     return context
//         .dependOnInheritedWidgetOfExactType<ChatControllerInhertedWidget>()!
//         .controller;
//   }

//   @override
//   bool updateShouldNotify(ChatControllerInhertedWidget oldWidget) {
//     return false;
//   }
// }
