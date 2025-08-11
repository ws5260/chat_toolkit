import 'dart:async';

import 'package:chat_toolkit/chat/message/entity/failed_message_entry.dart';
import 'package:chat_toolkit/chat/message/entity/message.dart';
import 'package:chat_toolkit/chat/message/entity/message_group.dart';
import 'package:flutter/material.dart';

typedef MessageDispatchCallback = Future<Message?> Function(Message);

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

  bool _isCollapsed = false;

  bool get isCollapsed => _isCollapsed;

  late final bool _reverse;
  bool get reverse => _reverse;

  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  setIsCollapsed(bool value) {
    _isCollapsed = value;
    notifyListeners();
  }

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

  ChatController({bool reverse = false}) {
    _reverse = reverse;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageGroups.clear();
    _dispatchResultController.close();
    _newReceiveMessageController.close();
    super.dispose();
  }

  void scrollToBottom() async {
    double getMovePosition() {
      if (reverse) {
        return 0.0;
      } else {
        return position.maxScrollExtent;
      }
    }

    if (hasClients) {
      double movePosition = getMovePosition();
      jumpTo(movePosition);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        movePosition = getMovePosition();
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

  bool isAtBottom({double threshold = 20}) {
    if (!hasClients) return true;
    if (reverse) {
      return position.pixels <= threshold;
    } else {
      return (position.maxScrollExtent - position.pixels) <= threshold;
    }
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
