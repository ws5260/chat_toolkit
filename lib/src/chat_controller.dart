import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'message/entity/failed_message_entry.dart';
import 'message/entity/message.dart';
import 'message/entity/message_group.dart';

/// Sends a [Message] to your backend; passed to [ChatController.dispatchMessage].
///
/// The callback receives the message exactly as it was passed to
/// [ChatController.dispatchMessage] (not the loading copy shown in the list).
/// Complete with:
///
/// * the stored message on success. It replaces the local bubble as-is, so it
///   may carry a server id or timestamp, and it should have
///   [Message.isLoading] set to `false`. If it is a [ReceiverMessage] (for
///   example a bot reply), it is also emitted on
///   [ChatController.newReceiveMessageStream].
/// * `null` on failure. The bubble is marked as failed ([Message.isFailed])
///   and can be sent again with [ChatController.retryMessage], which calls
///   this same callback.
/// * or throw a [MessageBlockedException] when the server refuses the
///   message. The bubble is removed and no retry is possible.
///
/// Any other error is not caught by the controller: it propagates out of
/// [ChatController.dispatchMessage] and the bubble keeps its loading
/// indicator. Catch errors inside the callback and return `null` instead.
///
/// ```dart
/// Future<Message?> send(Message message) async {
///   try {
///     final response = await api.send(message);
///     if (response.isBlocked) {
///       throw MessageBlockedException(code: response.code, message: response.text);
///     }
///     return message.copyWith(isLoading: false, timestamp: response.sentAt);
///   } on NetworkException {
///     return null; // shows retry / delete buttons
///   }
/// }
/// ```
typedef MessageDispatchCallback = Future<Message?> Function(Message);

/// Orders two messages that have the same [Message.timestamp].
///
/// Returns a negative number if `a` comes first, a positive number if `b`
/// comes first, or `0` when either order is fine (the sort is not stable, so
/// their order is then unspecified). Passed to [ChatController.new] as
/// `customSortCallback` and used only by [ChatController.setMessages]; messages
/// added later are not re-sorted with it.
///
/// ```dart
/// final controller = ChatController(
///   customSortCallback: (a, b) => a.id.compareTo(b.id),
/// );
/// ```
typedef CustomSortCallback = int Function(Message a, Message b);

/// Extra condition for adding [message] to an existing [group].
///
/// Passed to [ChatController.new] as `additionalGroupCondition`. It is checked
/// only when the default condition already holds: same side
/// ([Message.isSender]), same [Message.name], and the same minute as
/// [MessageGroup.timestamp] (the group's first message). Return `false` to
/// start a new group. [group] is read-only.
///
/// ```dart
/// final controller = ChatController(
///   // At most 10 messages per group.
///   additionalGroupCondition: (group, message) => group.messages.length < 10,
/// );
/// ```
typedef AdditionalGroupCondition =
    bool Function(MessageGroup group, Message message);

/// Thrown by a [MessageDispatchCallback] when the server refuses the message.
///
/// Unlike returning `null`, a block is not treated as a failure that can be
/// retried: [ChatController.dispatchMessage] removes the bubble and completes
/// with a [MessageDispatchResult] whose [MessageDispatchResult.exception] is
/// this exception, so you can show [message] to the user.
///
/// ```dart
/// final result = await controller.dispatchMessage(
///   message,
///   onDispatch: (message) async {
///     final response = await api.send(message);
///     if (response.isBlocked) {
///       throw MessageBlockedException(code: response.code, message: response.text);
///     }
///     return response.message;
///   },
/// );
/// final error = result.exception;
/// if (error is MessageBlockedException) showSnackBar(error.message);
/// ```
class MessageBlockedException implements Exception {
  /// Machine-readable reason for the block, as reported by your server.
  ///
  /// Not interpreted by the toolkit.
  final String code;

  /// Human-readable reason to show the user, as reported by your server.
  ///
  /// Not interpreted or localized by the toolkit.
  final String message;

  /// Creates a [MessageBlockedException].
  MessageBlockedException({required this.code, required this.message});

  @override
  String toString() => 'MessageBlockedException($code)';
}

/// Reported when [ChatController.retryMessage] is called for a message that
/// cannot be retried.
///
/// A message is retryable only while the controller holds a failed entry for
/// its [Message.id]: one created when its [MessageDispatchCallback] returned
/// `null`, or registered with [ChatController.registerFailedMessage]. The
/// entry is gone once the message was sent successfully, removed (for example
/// with [ChatController.removeMessageEverywhere]), or never existed.
///
/// It is not thrown: it is emitted as the [MessageDispatchResult.exception] of
/// a failed result on [ChatController.dispatchResultStream].
class MessageNotRetryableException implements Exception {
  /// Id of the message that could not be retried.
  final String messageId;

  /// Creates a [MessageNotRetryableException].
  MessageNotRetryableException(this.messageId);

  @override
  String toString() => 'MessageNotRetryableException($messageId)';
}

/// Outcome of sending a message with [ChatController.dispatchMessage] or
/// [ChatController.retryMessage].
///
/// Returned by [ChatController.dispatchMessage] and also emitted on
/// [ChatController.dispatchResultStream].
class MessageDispatchResult {
  /// The message as it was passed to [ChatController.dispatchMessage] or
  /// [ChatController.retryMessage].
  ///
  /// On success this is still the original message, not the one returned by
  /// the [MessageDispatchCallback]; find the stored one in
  /// [ChatController.messageGroups] by its [Message.id] if you need it.
  final Message message;

  /// Whether the message was sent successfully.
  final bool isSuccess;

  /// Why sending failed, or `null` when [isSuccess] is `true`.
  ///
  /// * A [MessageBlockedException] when the server refused the message (the
  ///   bubble was removed).
  /// * A [MessageNotRetryableException] when [ChatController.retryMessage]
  ///   was called for a message that cannot be retried.
  /// * A generic [Exception] when the [MessageDispatchCallback] returned
  ///   `null` (the bubble is shown as failed and can be retried).
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
/// Messages are kept as a list of [MessageGroup]s in chronological order
/// (see [messageGroups]). Change them only through this controller:
///
/// * [setMessages] replaces everything, e.g. with the latest page of history.
/// * [appendMessages] adds older messages at the beginning, e.g. from
///   [Chat.onScrollToTop].
/// * [addMessage] adds a message at the end, or updates one with the same
///   [Message.id].
/// * [dispatchMessage] sends a message through your backend, showing a
///   loading bubble, then the stored message, a failed bubble that can be
///   retried with [retryMessage], or nothing if the server blocked it.
/// * [removeMessageEverywhere] and [updateMessageAllRead] remove messages and
///   update read state.
///
/// Every change to the messages notifies the controller's listeners (see
/// [addListener]). Because it extends [ScrollController], listeners are also
/// notified on every scroll offset change, and it can be used to read or
/// change the scroll position. The list is laid out in reverse, so offset `0`
/// is the newest message.
///
/// Pass the controller to [Chat.chatController]. A controller you create is
/// yours to [dispose]; [Chat] does not dispose it. Use one controller per
/// [Chat].
///
/// ```dart
/// final controller = ChatController();
///
/// // Load the latest page of history.
/// controller.setMessages(await api.fetchLatest());
///
/// // Send a message typed by the user.
/// await controller.dispatchMessage(
///   SenderMessage(
///     name: 'Me',
///     timestamp: DateTime.now().toIso8601String(),
///     elements: [TextElement(text)],
///   ),
///   onDispatch: (message) async {
///     final stored = await api.send(message); // null on failure
///     return stored;
///   },
/// );
///
/// // Show a message pushed by the server.
/// controller.addMessage(incomingMessage);
/// ```
class ChatController extends ScrollController {
  final StreamController<MessageDispatchResult> _dispatchResultController =
      StreamController.broadcast();
  final StreamController<Message> _newReceiveMessageController =
      StreamController.broadcast();

  /// Emits the result of every [dispatchMessage] and [retryMessage] call.
  ///
  /// This is a broadcast stream: any number of listeners may subscribe, and
  /// results emitted while nobody listens are lost. Events are delivered
  /// asynchronously, after the message list has been updated. Besides the
  /// results also returned by [dispatchMessage], it carries the failed
  /// results of [retryMessage] calls for messages that cannot be retried
  /// (with a [MessageNotRetryableException]), which are reported nowhere
  /// else.
  ///
  /// The stream is closed by [dispose].
  ///
  /// ```dart
  /// controller.dispatchResultStream.listen((result) {
  ///   if (!result.isSuccess) log('Not sent: ${result.exception}');
  /// });
  /// ```
  Stream<MessageDispatchResult> get dispatchResultStream =>
      _dispatchResultController.stream;

  /// Emits the [ReceiverMessage]s returned by a [MessageDispatchCallback].
  ///
  /// When the callback passed to [dispatchMessage] completes with a receiver
  /// message (for example to show an incoming message with the same flow as a
  /// sent one), the stored message is emitted here. Messages added with
  /// [addMessage], [setMessages] or [appendMessages] are not emitted.
  ///
  /// [Chat] listens to it to auto-scroll or to show
  /// [ChatConfiguration.newReceiveMessageNotificationBuilder]. This is a
  /// broadcast stream, delivered asynchronously, and closed by [dispose].
  Stream<Message> get newReceiveMessageStream =>
      _newReceiveMessageController.stream;

  final List<MessageGroup> _messageGroups = [];

  /// The current message groups, oldest first.
  ///
  /// This is a read-only live view: it always reflects the controller's
  /// current state, and modifying it throws an [UnsupportedError]. Change
  /// messages through the methods of this controller. Copy it (for example
  /// with `List.of`) if you need a snapshot. Each group's
  /// [MessageGroup.messages] is likewise a read-only live view, oldest first.
  ///
  /// Groups are rebuilt by [setMessages] and may be created, extended, or
  /// removed by any other change, so do not hold on to a [MessageGroup]
  /// across changes. Empty after [dispose].
  ///
  /// ```dart
  /// final allMessages = [
  ///   for (final group in controller.messageGroups) ...group.messages,
  /// ];
  /// ```
  late final List<MessageGroup> messageGroups = UnmodifiableListView(
    _messageGroups,
  );

  final Map<String, FailedMessageEntry> _failedMessageEntries = {};

  final Set<String> _unreadMessageIds = {};

  // Ids of messages newly added by addMessage, with the time they were added, so [Chat] can play
  // the entrance animation once (see ChatConfiguration.messageAppearAnimationDuration).
  final Map<String, DateTime> _appearPendingIds = {};
  bool _suppressAppear = false;

  // A pending entry older than this is dropped: the message was not shown right away (e.g. the
  // user was scrolled far up), so animating it later when scrolled into view would look odd.
  static const Duration _appearWindow = Duration(seconds: 1);

  void _markAppear(String messageId) {
    if (_suppressAppear || messageId.isEmpty) return;
    final now = DateTime.now();
    _appearPendingIds.removeWhere((_, addedAt) => now.difference(addedAt) > _appearWindow);
    _appearPendingIds[messageId] = now;
  }

  bool _isDisposed = false;

  /// Whether [dispose] has been called.
  ///
  /// Check it before using the controller from an asynchronous callback that
  /// may complete after the [Chat] screen was closed.
  bool get isDisposed => _isDisposed;

  // Tie-breaker for messages that share the same timestamp.
  final CustomSortCallback? _customSortCallback;

  final AdditionalGroupCondition? _additionalGroupCondition;

  bool _canJoinGroup(MessageGroup group, Message message) =>
      _defaultCanJoinGroup(group, message) &&
      (_additionalGroupCondition?.call(group, message) ?? true);

  /// Notifies the listeners, unless the controller [isDisposed].
  ///
  /// Called for every message change and, as a [ScrollController], for every
  /// scroll offset change.
  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  // Incremented only when the message list changes; exposed to Chat through
  // ChatControllerInternal.messagesRevision.
  final ValueNotifier<int> _messagesRevision = ValueNotifier(0);

  // Also calls notifyListeners because direct controller listeners (e.g. Chat._onScroll)
  // have always been notified of message changes.
  void _notifyMessagesChanged() {
    if (_isDisposed) return;
    _messagesRevision.value++;
    notifyListeners();
  }

  /// Replaces all messages with [messages], e.g. the latest page of history.
  ///
  /// The messages may be in any order: they are sorted by [Message.timestamp]
  /// and then grouped (see [MessageGroup]). Messages with the same timestamp
  /// are ordered by the `customSortCallback` passed to [ChatController.new];
  /// without one, their relative order is not guaranteed. Every timestamp must
  /// be parsable by [DateTime.parse], since grouping compares them.
  ///
  /// * [messages] itself is sorted in place, so it must be modifiable.
  /// * When several messages share a non-empty [Message.id], the later one
  ///   in sorted order replaces the earlier one.
  /// * Messages with [Message.isRead] `false` are tracked for
  ///   [updateMessageAllRead]; previously tracked ones are forgotten.
  /// * The messages do not play the entrance animation of
  ///   [ChatConfiguration.messageAppearAnimationDuration].
  /// * Failed messages that can still be retried (see [retryMessage]) are
  ///   kept, after the newest message.
  ///
  /// Listeners are notified.
  ///
  /// ```dart
  /// final page = await api.fetchLatestMessages();
  /// controller.setMessages([
  ///   for (final dto in page)
  ///     dto.isMine
  ///         ? SenderMessage(id: dto.id, name: dto.author, timestamp: dto.sentAt, elements: [TextElement(dto.text)])
  ///         : ReceiverMessage(id: dto.id, name: dto.author, timestamp: dto.sentAt, elements: [TextElement(dto.text)]),
  /// ]);
  /// ```
  void setMessages(List<Message> messages) {
    _messageGroups.clear();
    _unreadMessageIds.clear();
    _appearPendingIds.clear();

    // Parse each timestamp once, not on every comparison.
    final entries = [
      for (final message in messages)
        (message: message, date: DateTime.tryParse(message.timestamp)),
    ];
    entries.sort((ea, eb) {
      final a = ea.message;
      final b = eb.message;
      final aDate = ea.date;
      final bDate = eb.date;

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
    for (int i = 0; i < entries.length; i++) {
      messages[i] = entries[i].message;
    }

    // addMessage re-positions failed messages on every call; keep that exact behavior when any
    // are registered (rare during a full reload).
    if (_failedMessageEntries.isNotEmpty) {
      _suppressAppear = true; // loaded history, not new messages
      try {
        for (final message in messages) {
          addMessage(message);
        }
      } finally {
        _suppressAppear = false;
      }
      return;
    }

    // Group in a single pass over the sorted list. Equivalent to calling addMessage for each
    // message, without its per-message duplicate scan over every group and per-message notify.
    final positions = <String, ({MessageGroup group, int index})>{};
    for (final message in messages) {
      if (message.id.isNotEmpty) {
        final existing = positions[message.id];
        if (existing != null) {
          // Same id seen before: replace it in place, as addMessage does.
          existing.group.mutableMessages[existing.index] = message;
          continue;
        }
      }
      final MessageGroup group;
      if (_messageGroups.isEmpty ||
          !_canJoinGroup(_messageGroups.last, message)) {
        group = MessageGroup(
          name: message.name,
          isSender: message.isSender,
          timestamp: message.timestamp,
          messages: [message],
        );
        _messageGroups.add(group);
      } else {
        group = _messageGroups.last;
        group.mutableMessages.add(message);
      }
      if (message.id.isNotEmpty) {
        positions[message.id] = (group: group, index: group.messages.length - 1);
      }
      if (message.isRead == false) {
        _unreadMessageIds.add(message.id);
      } else if (message.isRead == true) {
        _unreadMessageIds.remove(message.id);
      }
    }
    _notifyMessagesChanged();
  }

  /// Adds older [messages] to the beginning of the list, e.g. when loading
  /// history from [Chat.onScrollToTop].
  ///
  /// Pass them newest first: each message is inserted before the current
  /// oldest one, joining the oldest group when the grouping rules allow (see
  /// [MessageGroup]). The messages are not sorted and not checked for
  /// duplicate ids, so pass only messages older than the ones already loaded.
  ///
  /// Messages with [Message.isRead] `false` are tracked for
  /// [updateMessageAllRead]. The messages do not play the entrance animation
  /// of [ChatConfiguration.messageAppearAnimationDuration], and since the
  /// list is laid out from the newest message, what is on screen does not
  /// move. Listeners are notified once.
  ///
  /// ```dart
  /// Chat(
  ///   chatController: controller,
  ///   onScrollToTop: () async {
  ///     final older = await api.fetchBefore(oldestLoadedId); // newest first
  ///     controller.appendMessages(older);
  ///   },
  /// )
  /// ```
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
        _messageGroups.first.mutableMessages.insert(0, message);
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
  /// The list is always laid out in reverse: the newest message is at scroll
  /// offset `0`, so the chat opens at the newest message and older messages
  /// added by [appendMessages] do not move what is on screen.
  ///
  /// * `customSortCallback` orders messages with the same timestamp in
  ///   [setMessages]. See [CustomSortCallback].
  /// * `additionalGroupCondition` adds a condition for grouping messages.
  ///   See [AdditionalGroupCondition].
  /// * `reverse` is ignored and only kept so existing code still compiles.
  ///
  /// The controller starts empty. Call [dispose] when you no longer need it.
  ChatController({
    @Deprecated(
      'Ignored: the chat is always laid out from the newest message. '
      'Remove this argument. Will be removed in a future major version.',
    )
    bool? reverse,
    this._customSortCallback,
    this._additionalGroupCondition,
  });

  /// Always `true`: the list is laid out from the newest message (scroll offset `0`).
  @Deprecated(
    'Always true: the chat is always laid out from the newest message. '
    'Will be removed in a future major version.',
  )
  bool get reverse => true;

  // Whether [message] can join [group] by default: same side
  // ([Message.isSender]), same [Message.name] and same minute.
  static bool _defaultCanJoinGroup(MessageGroup group, Message message) {
    return group.isSender == message.isSender &&
        group.name == message.name &&
        _isSameMinute(
          DateTime.parse(group.timestamp),
          DateTime.parse(message.timestamp),
        );
  }

  /// Discards the messages and releases the resources of this controller.
  ///
  /// Clears [messageGroups], closes [dispatchResultStream] and
  /// [newReceiveMessageStream], and sets [isDisposed]. Listeners are not
  /// notified afterwards. Call it only when no [dispatchMessage] is pending.
  ///
  /// A controller passed to [Chat.chatController] is not disposed by [Chat];
  /// dispose it yourself, typically in your [State.dispose].
  @override
  void dispose() {
    _isDisposed = true;
    _messageGroups.clear();
    _unreadMessageIds.clear();
    _appearPendingIds.clear();
    _dispatchResultController.close();
    _newReceiveMessageController.close();
    _messagesRevision.dispose();
    super.dispose();
  }

  static const double _bottomEpsilon = 2.0;

  /// Jumps to the newest message (scroll offset `0`).
  ///
  /// Jumps without animation. Does nothing when the controller is not
  /// attached to a [Chat], is disposed, or is already at the newest message.
  /// Use [animateTo] with offset `0` for an animated scroll.
  void scrollToBottom() {
    if (_isDisposed || !hasClients) return;
    if (position.pixels.abs() <= _bottomEpsilon) return;
    jumpTo(0);
  }

  /// Adds [message] after the newest message and returns its group.
  ///
  /// Use it for messages pushed by your server or to update a message. The
  /// message is placed at the end regardless of its [Message.timestamp]; it
  /// joins the newest group when the grouping rules allow (see
  /// [MessageGroup]), otherwise a new group is created.
  ///
  /// * When a message with the same non-empty [Message.id] already exists,
  ///   it is replaced in place instead and keeps its position and group.
  ///   Use this to update a message, e.g. after editing its elements.
  /// * Failed messages that can still be retried (see [retryMessage]) stay
  ///   after the newest message: they are moved behind a newly added one.
  /// * A new message with [Message.isRead] `false` is tracked for
  ///   [updateMessageAllRead].
  /// * A new message plays the entrance animation when
  ///   [ChatConfiguration.messageAppearAnimationDuration] is set.
  ///
  /// The returned group is a read-only view; listeners are notified. Unlike
  /// [dispatchMessage], this does not scroll and does not emit on
  /// [newReceiveMessageStream].
  ///
  /// ```dart
  /// socket.onMessage((dto) {
  ///   controller.addMessage(
  ///     ReceiverMessage(id: dto.id, name: dto.author, timestamp: dto.sentAt, elements: [TextElement(dto.text)]),
  ///   );
  /// });
  /// ```
  MessageGroup addMessage(Message message) {
    if (message.id.isNotEmpty) {
      final existing = _groupOf(message.id);
      if (existing != null) {
        final index = existing.messages.indexWhere((m) => m.id == message.id);
        existing.mutableMessages[index] = message;
        _notifyMessagesChanged();
        return existing;
      }
    }
    _markAppear(message.id);
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
      messageGroup.mutableMessages.add(message);
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

        entry.messageGroup.mutableMessages.remove(failedMessage);
        if (entry.messageGroup.messages.isEmpty) {
          _messageGroups.remove(entry.messageGroup);
        }
        late final MessageGroup newGroup;
        if (_messageGroups.isNotEmpty &&
            _canJoinGroup(_messageGroups.last, failedMessage)) {
          newGroup = _messageGroups.last;
          newGroup.mutableMessages.add(failedMessage);
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
  /// A copy of the message with [Message.isLoading] `true` is added right
  /// away with [addMessage] (replacing a message with the same id, if any),
  /// so [BubbleConfiguration.loadingWidget] is shown; for a [SenderMessage]
  /// the list also jumps to the newest message. Then [onDispatch] is called
  /// with [message] as given, and when it completes:
  ///
  /// * If it returns a message, that message replaces the loading copy in the
  ///   same group, as-is. A returned [ReceiverMessage] is also emitted on
  ///   [newReceiveMessageStream].
  /// * If it returns `null`, the bubble is shown as failed (with
  ///   [Message.isFailed] `true`, after the newest message) and can be sent
  ///   again with [retryMessage], or deleted by the user (see
  ///   [Chat.onDeleteFailedMessage]).
  /// * If it throws a [MessageBlockedException], the bubble is removed and
  ///   the message cannot be retried.
  ///
  /// See [MessageDispatchCallback] for what the callback should return. Any
  /// other error thrown by [onDispatch] is not caught: the returned future
  /// completes with it and the bubble stays in its loading state.
  ///
  /// The returned [MessageDispatchResult] is also emitted on
  /// [dispatchResultStream]. Listeners are notified on each step. Several
  /// dispatches may run at the same time.
  ///
  /// It can also show an incoming message with the same flow: dispatching a
  /// [ReceiverMessage] with `(m) async => m` lets [Chat] auto-scroll or show
  /// [ChatConfiguration.newReceiveMessageNotificationBuilder].
  ///
  /// ```dart
  /// final result = await controller.dispatchMessage(
  ///   SenderMessage(
  ///     name: 'Me',
  ///     timestamp: DateTime.now().toIso8601String(),
  ///     elements: [TextElement(text)],
  ///   ),
  ///   onDispatch: (message) async {
  ///     final response = await api.send(message);
  ///     if (response.isBlocked) {
  ///       // Removes the bubble; result.exception is this exception.
  ///       throw MessageBlockedException(code: response.code, message: response.text);
  ///     }
  ///     if (!response.ok) return null; // failed bubble with retry / delete
  ///     return message.copyWith(isLoading: false, isFailed: false, timestamp: response.sentAt);
  ///   },
  /// );
  /// if (result.exception case MessageBlockedException(:final message)) {
  ///   showSnackBar(message);
  /// }
  /// ```
  Future<MessageDispatchResult> dispatchMessage(
    Message message, {
    required MessageDispatchCallback onDispatch,
  }) async {
    final messageGroup = addMessage(
      message.copyWith(isLoading: true, isFailed: false),
    );
    // Show the sent bubble right away, not only after onDispatch completes (a server round trip).
    if (message.isSender) {
      scrollToBottom();
    }
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
        _removeMessageAt(messageGroup, blockedIndex);
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
      messageGroup.mutableMessages[index] = result;
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
      _removeMessageAt(messageGroup, index);

      _failedMessageEntries[message.id] = FailedMessageEntry(
        messageId: message.id,
        messageGroup: messageGroup,
        onDispatch: onDispatch,
      );

      // The bubble already appeared; re-adding it as failed is not a new message.
      _suppressAppear = true;
      try {
        addMessage(message.copyWith(isLoading: false, isFailed: true));
      } finally {
        _suppressAppear = false;
      }
    }
    if (message.isSender) {
      // The bubble changed from the loading indicator to its content (or to failed).
      scrollToBottom();
    }
    if (_dispatchResultController.isClosed) return dispatchResult;
    _dispatchResultController.add(dispatchResult);

    return dispatchResult;
  }

  /// Makes an already loaded failed message with [messageId] retryable
  /// through [onDispatch], e.g. a failed message restored from local storage.
  ///
  /// Messages that failed in [dispatchMessage] are registered automatically;
  /// use this for failed messages you load yourself, which [retryMessage]
  /// would otherwise reject with a [MessageNotRetryableException].
  ///
  /// The message must already be in the list (added with [setMessages],
  /// [appendMessages] or [addMessage]); otherwise this does nothing. This does
  /// not change the message itself, so load it with [Message.isFailed] `true`
  /// for [Chat] to show its retry and delete buttons. Registering the same id
  /// again replaces its callback.
  ///
  /// ```dart
  /// final unsent = await localDb.loadUnsentMessages();
  /// controller.setMessages([
  ///   ...history,
  ///   for (final m in unsent) m.copyWith(isFailed: true),
  /// ]);
  /// for (final m in unsent) {
  ///   controller.registerFailedMessage(m.id, sendToServer);
  /// }
  /// ```
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
  /// [Chat] calls this when the retry button of a failed bubble is tapped;
  /// call it yourself for a custom retry action, e.g. from a
  /// [BubbleMenuItem]. The failed bubble is removed and [message] goes
  /// through [dispatchMessage] again with the stored
  /// [MessageDispatchCallback] (the one passed to [dispatchMessage] or
  /// [registerFailedMessage]), so it reappears as the newest message with a
  /// loading indicator. Note that the callback receives the failed message,
  /// with [Message.isFailed] `true`.
  ///
  /// The returned future completes once that dispatch has finished. Its
  /// result is not returned: it is emitted on [dispatchResultStream]. If it
  /// fails again, the message is shown as failed and stays retryable; on
  /// success it is no longer retryable.
  ///
  /// When the message is not retryable (see [MessageNotRetryableException]),
  /// nothing changes in the list and a failed result with a
  /// [MessageNotRetryableException] is emitted on [dispatchResultStream].
  ///
  /// ```dart
  /// BubbleMenuItem(
  ///   label: 'Resend',
  ///   enabled: request.message.isFailed,
  ///   onSelected: (context, request) => controller.retryMessage(request.message),
  /// )
  /// ```
  Future<void> retryMessage(Message message) async {
    final entry = _failedMessageEntries[message.id];
    if (entry == null) {
      _dispatchResultController.add(
        MessageDispatchResult(
          message: message,
          isSuccess: false,
          exception: MessageNotRetryableException(message.id),
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
          exception: MessageNotRetryableException(message.id),
        ),
      );
      return;
    }
    _removeMessage(failedGroup, message);

    await dispatchMessage(message, onDispatch: entry.onDispatch).then((result) {
      if (result.isSuccess) {
        _failedMessageEntries.remove(message.id);
      }
    });
  }

  /// Removes every message with the same [Message.id] as [message].
  ///
  /// Groups that become empty are removed, and the message is no longer
  /// retryable or tracked as unread. Nothing happens to your backend; delete
  /// the message there yourself. Listeners are notified even when no message
  /// matched.
  void removeMessageEverywhere(Message message) {
    for (final group in _messageGroups.toList()) {
      group.mutableMessages.removeWhere((m) => m.id == message.id);
    }
    _messageGroups.removeWhere((group) => group.messages.isEmpty);
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);
    _notifyMessagesChanged();
  }

  // Removes [message] from [group], and the group itself if it becomes empty.
  void _removeMessage(MessageGroup group, Message message) {
    group.mutableMessages.remove(message);
    if (group.messages.isEmpty) {
      _messageGroups.remove(group);
    }
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);

    _notifyMessagesChanged();
  }

  // Removes the message at [messageIndex] in [group], and the group itself
  // if it becomes empty.
  void _removeMessageAt(MessageGroup group, int messageIndex) {
    final message = group.mutableMessages.removeAt(messageIndex);
    if (group.messages.isEmpty) {
      _messageGroups.remove(group);
    }
    _failedMessageEntries.remove(message.id);
    _unreadMessageIds.remove(message.id);

    _notifyMessagesChanged();
  }

  // Whether [a] and [b] fall within the same minute.
  static bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  /// Whether the list is scrolled within [threshold] logical pixels of the
  /// newest message.
  ///
  /// Returns `true` when not attached to a scroll view. Useful to decide
  /// whether to call [scrollToBottom] after adding a message.
  bool isAtBottom({double threshold = 20}) {
    if (!hasClients) return true;
    return position.pixels <= threshold;
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
  ///
  /// Each tracked unread message is replaced by a copy with
  /// [Message.isRead] `true`, which updates
  /// [BubbleConfiguration.readIndicatorBuilder]. Tracked are the messages
  /// that were unread when added by [setMessages], [appendMessages], a new
  /// message in [addMessage], or a result of [dispatchMessage]; a message
  /// that became unread by being replaced through [addMessage] is not
  /// tracked. Messages with [Message.isRead] `null` are never changed.
  ///
  /// Listeners are notified only if a message changed. This does not tell
  /// your backend; call it when your server reports that the messages were
  /// read.
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
            group.mutableMessages[index] = message.copyWith(isRead: true);
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

/// Toolkit-internal access to [ChatController], used by [Chat].
///
/// Not exported from `package:chat_toolkit/chat_toolkit.dart`, so apps cannot call it.
extension ChatControllerInternal on ChatController {
  /// Whether the message with [messageId] was just added and should play its entrance
  /// animation. Returns `true` at most once per added message.
  ///
  /// Called by [Chat] when it first builds the message.
  bool takeAppearAnimation(String messageId) {
    final addedAt = _appearPendingIds.remove(messageId);
    return addedAt != null &&
        DateTime.now().difference(addedAt) <= ChatController._appearWindow;
  }

  /// Incremented only when the message list changes.
  ///
  /// ScrollController calls notifyListeners on every scroll offset change, so
  /// the list view listens to this instead of the controller; otherwise the
  /// whole list would be rebuilt on every scroll frame.
  ValueListenable<int> get messagesRevision => _messagesRevision;

  /// Removes [message] from [group], and the group itself if it becomes empty.
  void removeMessageFromGroup(MessageGroup group, Message message) =>
      _removeMessage(group, message);

  /// Scrolls toward older messages by [offset].
  void scrollToTopByValue(double offset) {
    if (!hasClients) return;
    final currentOffset = position.pixels;
    if (currentOffset >= position.maxScrollExtent) return;
    jumpTo(currentOffset + offset);
  }

  /// Scrolls toward newer messages by [offset]. Offset direction is the
  /// opposite of [scrollToTopByValue].
  void scrollToBottomByValue(double offset) {
    if (!hasClients) return;
    final currentOffset = position.pixels;
    if (currentOffset <= 0) return;
    jumpTo(currentOffset - offset);
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
}
