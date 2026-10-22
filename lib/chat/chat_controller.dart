import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'message/entity/failed_message_entry.dart';
import 'message/entity/message.dart';
import 'message/entity/message_group.dart';

typedef MessageDispatchCallback = Future<Message?> Function(Message);
typedef CustomSortCallback = int Function(Message a, Message b);

/// Thrown by a dispatch callback when the server refuses to send the message.
class MessageBlockedException implements Exception {
  /// The resultCode of the server's [ResponseCode].
  final String code;

  /// Text to show the agent, used as-is from the server (already localized).
  final String message;

  MessageBlockedException({required this.code, required this.message});

  @override
  String toString() => 'MessageBlockedException($code)';
}

class MessageDispatchResult {
  final Message message;
  final bool isSuccess;
  final Exception? exception;

  MessageDispatchResult(
      {required this.message, required this.isSuccess, this.exception});
}

class ChatController extends ScrollController {
  final StreamController<MessageDispatchResult> _dispatchResultController =
      StreamController.broadcast();
  final StreamController<Message> _newReceiveMessageController =
      StreamController.broadcast();

  Stream<MessageDispatchResult> get dispatchResultStream =>
      _dispatchResultController.stream;

  Stream<Message> get newReceiveMessageStream =>
      _newReceiveMessageController.stream;

  final List<MessageGroup> _messageGroups = [];
  List<MessageGroup> get messageGroups => _messageGroups;

  final Map<String, FailedMessageEntry> _failedMessageEntries = {};

  final Set<String> _unreadMessageIds = {};

  bool _isCollapsed = false;

  bool get isCollapsed => _isCollapsed;

  late final bool _reverse;
  bool get reverse => _reverse;

  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  // Tie-breaker for messages that share the same timestamp.
  final CustomSortCallback? _customSortCallback;

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

  void setIsCollapsed(bool value) {
    _isCollapsed = value;
    notifyListeners();
  }

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
      if (_messageGroups.first.isSender == message.isSender &&
          isSameMinute(
            DateTime.parse(_messageGroups.first.timestamp),
            DateTime.parse(message.timestamp),
          )) {
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

  ChatController({bool reverse = false, this._customSortCallback}) {
    _reverse = reverse;
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
        _messageGroups.last.isSender != message.isSender ||
        !isSameMinute(
          DateTime.parse(_messageGroups.last.timestamp),
          DateTime.parse(message.timestamp),
        )) {
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
        _failedMessageEntries[failedId] =
            entry.copyWith(messageGroup: newGroup);
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

  Future<MessageDispatchResult> dispatchMessage(
    Message message, {
    required MessageDispatchCallback onDispatch,
  }) async {
    final messageGroup =
        addMessage(message.copyWith(isLoading: true, isFailed: false));
    late final MessageDispatchResult dispatchResult;
    late final Message? result;

    try {
      result = await onDispatch(message);
    } on MessageBlockedException catch (e) {
      // A block is not a failure: remove the bubble and do not register a retry entry.
      final blockedIndex = messageGroup.messages
          .indexWhere((element) => element.id == message.id);
      if (blockedIndex >= 0) {
        removeMessageGroupAt(messageGroup, blockedIndex);
      }
      final blockedResult = MessageDispatchResult(
          message: message, isSuccess: false, exception: e);
      _dispatchResultController.add(blockedResult);
      _notifyMessagesChanged();
      return blockedResult;
    }
    final index =
        messageGroup.messages.indexWhere((element) => element.id == message.id);
    if (result != null) {
      messageGroup.messages[index] = result;
      messageGroup.sortMessages();
      dispatchResult = MessageDispatchResult(
          message: message, isSuccess: true, exception: null);
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

  // Registers a failed message loaded from history as retryable via [onDispatch].
  void registerFailedMessage(
      String messageId, MessageDispatchCallback onDispatch) {
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

  void removeMessageEverywhere(Message message) {
    for (final group in _messageGroups.toList()) {
      group.messages.removeWhere((m) => m.id == message.id);
    }
    _messageGroups.removeWhere((group) => group.messages.isEmpty);
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);
    _notifyMessagesChanged();
  }

  void removeMessageFromGroup(MessageGroup group, Message message) {
    group.messages.remove(message);
    if (group.messages.isEmpty) {
      _messageGroups.remove(group);
    }
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);

    _notifyMessagesChanged();
  }

  void removeMessageGroupAt(MessageGroup group, int messageIndex) {
    final message = group.messages.removeAt(messageIndex);
    if (group.messages.isEmpty) {
      _messageGroups.remove(group);
    }
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);

    _notifyMessagesChanged();
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

  bool containsMessageId(String messageId) {
    for (final group in _messageGroups) {
      if (group.messages.any((m) => m.id == messageId)) {
        return true;
      }
    }
    return false;
  }

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
