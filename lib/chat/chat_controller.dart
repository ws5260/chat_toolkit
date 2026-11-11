import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'message/entity/failed_message_entry.dart';
import 'message/entity/message.dart';
import 'message/entity/message_group.dart';

/// Sends [Message] to your backend.
///
/// Return the stored message (it replaces the local one, so it may carry a
/// server id or timestamp) on success, or `null` on failure. Throw
/// [MessageBlockedException] when the server refuses the message.
typedef MessageDispatchCallback = Future<Message?> Function(Message);

/// Orders two messages that have the same timestamp.
///
/// Returns a negative number if `a` comes first, a positive number if `b`
/// comes first, or `0` to keep their order.
typedef CustomSortCallback = int Function(Message a, Message b);

/// Extra condition for adding [message] to an existing [group].
///
/// Checked in addition to [ChatController.defaultCanJoinGroup]; return
/// `false` to start a new group.
typedef AdditionalGroupCondition =
    bool Function(MessageGroup group, Message message);

/// Thrown by a dispatch callback when the server refuses to send the message.
class MessageBlockedException implements Exception {
  /// The resultCode of the server's `ResponseCode`.
  final String code;

  /// Text to show the agent, used as-is from the server (already localized).
  final String message;

  /// Creates a [MessageBlockedException].
  MessageBlockedException({required this.code, required this.message});

  @override
  String toString() => 'MessageBlockedException($code)';
}

/// Outcome of sending a message with [ChatController.dispatchMessage].
///
/// Also emitted on [ChatController.dispatchResultStream].
class MessageDispatchResult {
  /// The message that was sent.
  final Message message;

  /// Whether the message was sent successfully.
  final bool isSuccess;

  /// The error when [isSuccess] is `false`.
  ///
  /// A [MessageBlockedException] when the server refused the message.
  final Exception? exception;

  /// Creates a [MessageDispatchResult].
  MessageDispatchResult({
    required this.message,
    required this.isSuccess,
    this.exception,
  });
}

/// Holds the messages of a [Chat] and controls its scroll position.
///
/// Messages are kept as a list of [MessageGroup]s in chronological order.
/// Use [setMessages] to load history, [appendMessages] to prepend older
/// messages, [addMessage] for incoming messages and [dispatchMessage] to send
/// a message with loading, failure and retry handling.
///
/// Since it extends [ScrollController], it can also be used to read or change
/// the scroll position.
class ChatController extends ScrollController {
  final StreamController<MessageDispatchResult> _dispatchResultController =
      StreamController.broadcast();
  final StreamController<Message> _newReceiveMessageController =
      StreamController.broadcast();

  /// Emits the result of every [dispatchMessage] and [retryMessage] call.
  Stream<MessageDispatchResult> get dispatchResultStream =>
      _dispatchResultController.stream;

  /// Emits receiver messages returned by a dispatch callback.
  ///
  /// Used by [Chat] to show [ChatConfiguration.newReceiveMessageNotificationBuilder].
  Stream<Message> get newReceiveMessageStream =>
      _newReceiveMessageController.stream;

  final List<MessageGroup> _messageGroups = [];

  /// The current message groups, oldest first.
  ///
  /// Do not modify this list directly; use the methods of this controller.
  List<MessageGroup> get messageGroups => _messageGroups;

  final Map<String, FailedMessageEntry> _failedMessageEntries = {};

  final Set<String> _unreadMessageIds = {};

  bool _isCollapsed = false;

  /// A flag you can use to track whether the chat is collapsed.
  ///
  /// Not used by the toolkit itself. Change it with [setIsCollapsed].
  bool get isCollapsed => _isCollapsed;

  late final bool _reverse;

  /// Whether the list is laid out in reverse, with the newest messages at
  /// scroll offset `0`.
  bool get reverse => _reverse;

  bool _isDisposed = false;

  /// Whether [dispose] has been called.
  bool get isDisposed => _isDisposed;

  // Tie-breaker for messages that share the same timestamp.
  final CustomSortCallback? _customSortCallback;

  final AdditionalGroupCondition? _additionalGroupCondition;

  bool _canJoinGroup(MessageGroup group, Message message) =>
      defaultCanJoinGroup(group, message) &&
      (_additionalGroupCondition?.call(group, message) ?? true);

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Incremented only when the message list changes.
  /// ScrollController calls notifyListeners on every scroll offset change, so the list
  /// view should listen to this instead of the controller; otherwise the whole list
  /// is rebuilt on every scroll frame.
  ValueListenable<int> get messagesRevision => _messagesRevision;
  final ValueNotifier<int> _messagesRevision = ValueNotifier(0);

  // Also calls notifyListeners because direct controller listeners (e.g. Chat._onScroll)
  // have always been notified of message changes.
  void _notifyMessagesChanged() {
    if (_isDisposed) return;
    _messagesRevision.value++;
    notifyListeners();
  }

  /// Sets [isCollapsed] and notifies listeners.
  void setIsCollapsed(bool value) {
    _isCollapsed = value;
    notifyListeners();
  }

  /// Replaces all messages with [messages].
  ///
  /// The messages are sorted by [Message.timestamp] (using the custom sort
  /// callback for equal timestamps) and grouped. Messages with unparsable
  /// timestamps are placed last. Note that [messages] is sorted in place.
  void setMessages(List<Message> messages) {
    _messageGroups.clear();
    _unreadMessageIds.clear();
    messages.sort((a, b) {
      final aDate = DateTime.tryParse(a.timestamp);
      final bDate = DateTime.tryParse(b.timestamp);

      // Messages with unparsable timestamps sort last.
      if (aDate == null || bDate == null) {
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        return -1;
      }

      // Compare by time first.
      final timeComparison = aDate.compareTo(bDate);

      // Different times: chronological order wins.
      if (timeComparison != 0) {
        return timeComparison;
      }

      // Same time: defer to the custom sort, if any.
      if (_customSortCallback != null) {
        return _customSortCallback(a, b);
      }
      return 0;
    });

    for (final message in messages) {
      addMessage(message);
    }
  }

  /// Adds older [messages] to the beginning of the list, e.g. when loading
  /// history from [Chat.onScrollToTop].
  ///
  /// Pass them newest first: each message is inserted before the current
  /// oldest one.
  void appendMessages(List<Message> messages) {
    for (final message in messages) {
      if (message.isRead != null && message.isRead == false) {
        _unreadMessageIds.add(message.id);
      }
      if (_messageGroups.isEmpty) {
        _messageGroups.add(
          MessageGroup(
            name: message.name,
            isSender: message.isSender,
            timestamp: message.timestamp,
            messages: [message],
          ),
        );
        continue;
      }
      if (_canJoinGroup(_messageGroups.first, message)) {
        _messageGroups.first.messages.insert(0, message);
      } else {
        _messageGroups.insert(
          0,
          MessageGroup(
            name: message.name,
            isSender: message.isSender,
            timestamp: message.timestamp,
            messages: [message],
          ),
        );
      }
    }
    _notifyMessagesChanged();
  }

  /// Creates a [ChatController].
  ///
  /// * [reverse] lays out the list in reverse so it starts at the newest
  ///   message. Defaults to `false`.
  /// * `customSortCallback` orders messages with the same timestamp.
  /// * `additionalGroupCondition` adds a condition for grouping messages.
  ChatController({
    bool reverse = false,
    this._customSortCallback,
    this._additionalGroupCondition,
  }) {
    _reverse = reverse;
  }

  /// Whether [message] can join [group] by default: same side
  /// ([Message.isSender]), same [Message.name] and same minute.
  bool defaultCanJoinGroup(MessageGroup group, Message message) {
    return group.isSender == message.isSender &&
        group.name == message.name &&
        isSameMinute(
          DateTime.parse(group.timestamp),
          DateTime.parse(message.timestamp),
        );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageGroups.clear();
    _unreadMessageIds.clear();
    _dispatchResultController.close();
    _newReceiveMessageController.close();
    _messagesRevision.dispose();
    super.dispose();
  }

  static const double _bottomEpsilon = 2.0;

  /// Jumps to the newest message.
  void scrollToBottom() {
    if (_isDisposed || !hasClients) return;
    final target = reverse ? 0.0 : position.maxScrollExtent;
    if ((position.pixels - target).abs() <= _bottomEpsilon) return;
    jumpTo(target);
  }

  /// Scrolls toward older messages by [offset].
  void scrollToTopByValue(double offset) {
    if (!hasClients) return;
    final currentOffset = position.pixels;
    if (reverse) {
      if (currentOffset >= position.maxScrollExtent) return;
      jumpTo(currentOffset + offset);
    } else {
      if (currentOffset <= 0) return;
      jumpTo(currentOffset - offset);
    }
  }

  /// Scrolls toward newer messages by [offset]. Offset direction is the opposite of [scrollToTopByValue].
  void scrollToBottomByValue(double offset) {
    if (!hasClients) return;
    final currentOffset = position.pixels;
    if (reverse) {
      if (currentOffset <= 0) return;
      jumpTo(currentOffset - offset);
    } else {
      if (currentOffset >= position.maxScrollExtent) return;
      jumpTo(currentOffset + offset);
    }
  }

  /// Adds [message] to its group. A message whose id already exists is not added again.
  /// Adds [message] after the newest message and returns its group.
  ///
  /// When a message with the same [Message.id] already exists, it is
  /// replaced in place instead, which is useful for updating a message.
  MessageGroup addMessage(Message message) {
    if (message.id.isNotEmpty) {
      final existing = _groupOf(message.id);
      if (existing != null) {
        final index = existing.messages.indexWhere((m) => m.id == message.id);
        existing.messages[index] = message;
        _notifyMessagesChanged();
        return existing;
      }
    }
    // _messages.add(message); _messages.sort((a, b) { if (a.isFailed == b.isFailed) return 0; if (a.is…
    late final MessageGroup messageGroup;
    if (_messageGroups.isEmpty ||
        !_canJoinGroup(_messageGroups.last, message)) {
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
      _failedMessageEntries[message.id] = _failedMessageEntries[message.id]!
          .copyWith(messageGroup: messageGroup);
    }

    if (_failedMessageEntries.isNotEmpty) {
      final failedIds = List<String>.from(_failedMessageEntries.keys);

      for (final failedId in failedIds) {
        final entry = _failedMessageEntries[failedId]!;
        final failedMessage = entry.messageGroup.messages.firstWhere(
          (m) => m.id == failedId,
        );

        entry.messageGroup.messages.remove(failedMessage);
        if (entry.messageGroup.messages.isEmpty) {
          _messageGroups.remove(entry.messageGroup);
        }
        late final MessageGroup newGroup;
        if (_messageGroups.isNotEmpty &&
            _canJoinGroup(_messageGroups.last, failedMessage)) {
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
    if (message.isRead == false) {
      _unreadMessageIds.add(message.id);
    } else if (message.isRead == true) {
      _unreadMessageIds.remove(message.id);
    }
    _notifyMessagesChanged();
    return messageGroup;
  }

  /// Sends [message] through [onDispatch] and tracks its state in the list.
  ///
  /// The message is shown with a loading indicator right away. Then:
  ///
  /// * If [onDispatch] returns a message, it replaces the local one.
  /// * If it returns `null`, the message is marked as failed and can be
  ///   retried with [retryMessage].
  /// * If it throws [MessageBlockedException], the message is removed.
  ///
  /// The result is returned and also emitted on [dispatchResultStream].
  ///
  /// ```dart
  /// await controller.dispatchMessage(
  ///   SenderMessage(name: 'Me', timestamp: DateTime.now().toIso8601String(), elements: [TextElement(text)]),
  ///   onDispatch: (message) => api.send(message),
  /// );
  /// ```
  Future<MessageDispatchResult> dispatchMessage(
    Message message, {
    required MessageDispatchCallback onDispatch,
  }) async {
    final messageGroup = addMessage(
      message.copyWith(isLoading: true, isFailed: false),
    );
    late final MessageDispatchResult dispatchResult;
    late final Message? result;

    try {
      result = await onDispatch(message);
    } on MessageBlockedException catch (e) {
      // A block is not a failure: remove the bubble and do not register a retry entry.
      final blockedIndex = messageGroup.messages.indexWhere(
        (element) => element.id == message.id,
      );
      if (blockedIndex >= 0) {
        removeMessageGroupAt(messageGroup, blockedIndex);
      }
      final blockedResult = MessageDispatchResult(
        message: message,
        isSuccess: false,
        exception: e,
      );
      _dispatchResultController.add(blockedResult);
      _notifyMessagesChanged();
      return blockedResult;
    }
    final index = messageGroup.messages.indexWhere(
      (element) => element.id == message.id,
    );
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
      if (result.isRead == true) {
        _unreadMessageIds.remove(result.id);
      } else if (result.isRead == false) {
        _unreadMessageIds.add(result.id);
      }
      _notifyMessagesChanged();
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
    if (message.isSender) {
      scrollToBottom();
    }
    if (_dispatchResultController.isClosed) return dispatchResult;
    _dispatchResultController.add(dispatchResult);

    return dispatchResult;
  }

  /// Makes an already loaded failed message with [messageId] retryable
  /// through [onDispatch], e.g. a failed message restored from local storage.
  void registerFailedMessage(
    String messageId,
    MessageDispatchCallback onDispatch,
  ) {
    for (final group in _messageGroups) {
      for (final m in group.messages) {
        if (m.id != messageId) continue;
        _failedMessageEntries[messageId] = FailedMessageEntry(
          messageId: messageId,
          messageGroup: group,
          onDispatch: onDispatch,
        );
        return;
      }
    }
  }

  /// Sends a failed [message] again with the callback it was originally
  /// dispatched with.
  ///
  /// Emits a failed result on [dispatchResultStream] when the message is not
  /// retryable.
  Future retryMessage(Message message) async {
    final entry = _failedMessageEntries[message.id];
    if (entry == null) {
      _dispatchResultController.add(
        MessageDispatchResult(
          message: message,
          isSuccess: false,
          exception: Exception("Failed to dispatch message"),
        ),
      );
      return;
    }
    final failedGroup = entry.messageGroup;

    if (failedGroup.messages.isEmpty) {
      _dispatchResultController.add(
        MessageDispatchResult(
          message: message,
          isSuccess: false,
          exception: Exception("Failed to dispatch message"),
        ),
      );
      return;
    }
    removeMessageFromGroup(failedGroup, message);

    await dispatchMessage(message, onDispatch: entry.onDispatch).then((result) {
      if (result.isSuccess) {
        _failedMessageEntries.remove(message.id);
      }
    });
  }

  /// Removes every message with the same [Message.id] as [message].
  void removeMessageEverywhere(Message message) {
    for (final group in _messageGroups.toList()) {
      group.messages.removeWhere((m) => m.id == message.id);
    }
    _messageGroups.removeWhere((group) => group.messages.isEmpty);
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);
    _notifyMessagesChanged();
  }

  /// Removes [message] from [group], and the group itself if it becomes empty.
  void removeMessageFromGroup(MessageGroup group, Message message) {
    group.messages.remove(message);
    if (group.messages.isEmpty) {
      _messageGroups.remove(group);
    }
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);

    _notifyMessagesChanged();
  }

  /// Removes the message at [messageIndex] in [group], and the group itself
  /// if it becomes empty.
  void removeMessageGroupAt(MessageGroup group, int messageIndex) {
    final message = group.messages.removeAt(messageIndex);
    if (group.messages.isEmpty) {
      _messageGroups.remove(group);
    }
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);

    _notifyMessagesChanged();
  }

  /// Whether [message] and [other] were sent on different calendar days.
  ///
  /// Returns `false` when either timestamp cannot be parsed.
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

  /// Whether [a] and [b] fall within the same minute.
  bool isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  /// Whether the list is scrolled within [threshold] logical pixels of the
  /// newest message. Returns `true` when not attached to a scroll view.
  bool isAtBottom({double threshold = 20}) {
    if (!hasClients) return true;
    if (reverse) {
      return position.pixels <= threshold;
    } else {
      return (position.maxScrollExtent - position.pixels) <= threshold;
    }
  }

  /// The group containing this message, or null if none.
  MessageGroup? _groupOf(String messageId) {
    for (final group in _messageGroups) {
      if (group.messages.any((m) => m.id == messageId)) return group;
    }
    return null;
  }

  /// Whether a message with [messageId] is in the list.
  bool containsMessageId(String messageId) {
    for (final group in _messageGroups) {
      if (group.messages.any((m) => m.id == messageId)) {
        return true;
      }
    }
    return false;
  }

  /// Marks every unread message ([Message.isRead] is `false`) as read.
  void updateMessageAllRead() {
    if (_unreadMessageIds.isEmpty) return;

    bool hasChanges = false;
    final idsToUpdate = Set<String>.from(_unreadMessageIds);

    for (final messageId in idsToUpdate) {
      for (final group in _messageGroups) {
        final index = group.messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final message = group.messages[index];
          // Only mark messages that are still unread.
          if (message.isRead == false) {
            group.messages[index] = message.copyWith(isRead: true);
            hasChanges = true;
          }
        }
      }
    }

    _unreadMessageIds.clear();

    if (hasChanges) {
      _notifyMessagesChanged();
    }
  }
}
