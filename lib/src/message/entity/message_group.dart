import 'dart:collection';

import 'message.dart';

/// Consecutive messages from the same author, shown under one profile.
///
/// A message joins the neighboring group (the newest one for
/// [ChatController.addMessage], the oldest one for
/// [ChatController.appendMessages]) when it is on the same side
/// ([Message.isSender]), has the same [Message.name], and was sent in the
/// same calendar minute as the group's [timestamp]; and, if one was passed to
/// [ChatController.new], when its [AdditionalGroupCondition] returns `true`.
/// Otherwise it starts a new group. [Chat] shows one profile per group
/// (built by [BubbleConfiguration.buildProfile]) and the timestamp only
/// beside the group's last bubble.
///
/// Groups are created and updated by [ChatController]; read them from
/// [ChatController.messageGroups]. A group is read-only for apps: change
/// messages through the controller's methods. Its [messages] list is a live
/// view that changes when the controller adds or removes messages, and a
/// group may be dropped or replaced by later changes (always by
/// [ChatController.setMessages]), so do not keep a group around.
class MessageGroup {
  final List<Message> _messages;

  /// Messages in this group, oldest first. Never empty while the group is in
  /// [ChatController.messageGroups].
  ///
  /// This is a read-only live view; modifying it throws an
  /// [UnsupportedError]. Copy it (for example with `List.of`) for a
  /// snapshot.
  late final List<Message> messages = UnmodifiableListView(_messages);

  /// Author name shared by the messages ([Message.name]).
  final String name;

  /// Whether the messages are [SenderMessage]s ([Message.isSender]).
  final bool isSender;

  /// Timestamp of the message that started the group.
  ///
  /// New messages are compared against it for the same-minute rule. This is
  /// the oldest message for groups built by [ChatController.setMessages] or
  /// [ChatController.addMessage], but the newest one for a group started by
  /// [ChatController.appendMessages], which adds messages from newest to
  /// oldest.
  final String timestamp;

  /// Creates a [MessageGroup] holding a copy of [messages].
  ///
  /// Apps do not need this: [ChatController] creates the groups. It is useful
  /// for testing an [AdditionalGroupCondition]. A group created this way is
  /// not part of any [ChatController].
  ///
  /// ```dart
  /// final group = MessageGroup(
  ///   name: 'Alice',
  ///   isSender: false,
  ///   timestamp: first.timestamp,
  ///   messages: [first],
  /// );
  /// expect(myCondition(group, second), isTrue);
  /// ```
  MessageGroup({
    required List<Message> messages,
    required this.name,
    required this.isSender,
    required this.timestamp,
  }) : _messages = List.of(messages);

  @override
  String toString() =>
      'MessageGroup(name: $name, isSender: $isSender, timestamp: $timestamp, '
      'messages: ${_messages.length})';
}

/// Toolkit-internal mutation of [MessageGroup], used by `ChatController`.
///
/// Not exported from `package:chat_toolkit/chat_toolkit.dart`.
extension MessageGroupInternal on MessageGroup {
  /// The mutable list behind [MessageGroup.messages].
  List<Message> get mutableMessages => _messages;

  /// Sorts the messages by timestamp, placing failed and then loading sender
  /// messages last.
  void sortMessages() {
    _messages.sort((a, b) {
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
