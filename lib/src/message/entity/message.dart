import 'package:uuid/uuid.dart';

import '../elements/message_element.dart';

/// Base class for a single chat message.
///
/// Use [SenderMessage] for messages sent by the current user and
/// [ReceiverMessage] for messages from other participants; which one a
/// message is decides its side of the chat (see
/// [ChatConfiguration.senderAlignment]) and its bubble and profile builders.
/// The content of a message is a list of [MessageElement]s, which you
/// implement for each content type (text, image, file, ...).
///
/// Messages are immutable: to change one, create a copy with [copyWith] and
/// pass it to [ChatController.addMessage], which replaces the message with
/// the same [id]. Messages have no value equality; the controller matches
/// them by [id].
abstract class Message {
  /// Unique identifier of the message.
  ///
  /// Used to find, update and deduplicate messages in [ChatController]:
  /// adding a message whose id already exists replaces the existing one.
  /// Keep ids unique within a chat. An empty id is allowed but disables
  /// this matching for that message.
  final String id;

  /// Optional identifier assigned by your server.
  ///
  /// Not used by the toolkit itself; keep it here to map local messages to
  /// server records.
  final String? serverUuid;

  /// Time the message was sent, as a string parsable by [DateTime.parse]
  /// (e.g. ISO 8601).
  ///
  /// Used for ordering ([ChatController.setMessages]), grouping consecutive
  /// messages (same minute, see [MessageGroup]), date separators and the
  /// default [BubbleConfiguration.timeBuilder]. A timestamp that
  /// [DateTime.parse] cannot parse makes grouping and the default time and
  /// date builders throw a [FormatException].
  final String timestamp;

  /// Display name of the author.
  ///
  /// Consecutive messages from the same author within the same minute are
  /// grouped, and the name is passed to the profile builders.
  final String name;

  /// Content of the message, rendered in order inside one bubble.
  ///
  /// Each element's [MessageElement.toWidget] is called when the bubble is
  /// built; the widgets are stacked vertically with a small gap. Not built
  /// while [isLoading] is `true`.
  final List<MessageElement> elements;

  /// Whether the message is still being sent.
  ///
  /// While `true`, [BubbleConfiguration.loadingWidget] is shown in the bubble
  /// instead of the [elements], and the timestamp and read indicator are
  /// hidden.
  /// Set by [ChatController.dispatchMessage]; you rarely set it yourself.
  final bool isLoading;

  /// Whether sending the message failed.
  ///
  /// Failed sender messages show retry and delete buttons instead of the
  /// timestamp (see [ChatController.retryMessage] and
  /// [Chat.onDeleteFailedMessage]). Set by [ChatController.dispatchMessage]
  /// when sending fails. Always `false` for a [ReceiverMessage].
  final bool isFailed;

  /// Read state of the message.
  ///
  /// `null` means read state is not tracked for this message, so no read
  /// indicator is shown. Otherwise [BubbleConfiguration.readIndicatorBuilder]
  /// (if set) builds an indicator for it, and
  /// [ChatController.updateMessageAllRead] turns `false` into `true`.
  final bool? isRead;

  /// Maximum width of this message's bubble.
  ///
  /// Overrides [BubbleConfiguration.maxWidth] when not `null`.
  final double? width;

  /// Creates a message. Use [SenderMessage] or [ReceiverMessage] instead.
  Message({
    required this.name,
    required this.id,
    this.serverUuid,
    required this.timestamp,
    required this.elements,
    this.isLoading = false,
    this.isFailed = false,
    this.isRead,
    this.width,
  });

  /// Whether this is a [SenderMessage] (sent by the current user).
  bool get isSender => this is SenderMessage;

  /// A one-line summary of this message: the [MessageElement.previewText] of
  /// its elements, joined with spaces (line breaks become spaces). Empty when
  /// no element has one.
  ///
  /// Handy for a new message notice that shows who wrote what:
  ///
  /// ```dart
  /// ChatConfiguration(
  ///   newReceiveMessageNotificationBuilder: (context, message, controller) =>
  ///       Text('${message.name}: ${message.previewText}'),
  /// )
  /// ```
  String get previewText => elements
      .map((e) => e.previewText?.trim())
      .whereType<String>()
      .where((text) => text.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  /// Returns a copy of this message with the given fields replaced.
  ///
  /// The copy has the same type as this message. [name] and [serverUuid]
  /// cannot be changed, and a field cannot be reset to `null` (passing
  /// `null` keeps the current value).
  ///
  /// ```dart
  /// controller.addMessage(
  ///   message.copyWith(elements: [TextElement('edited text')]),
  /// );
  /// ```
  Message copyWith({
    String? id,
    String? timestamp,
    bool? isLoading,
    List<MessageElement>? elements,
    bool? isFailed,
    double? width,
    bool? isRead,
  });
}

/// A message received from another participant.
///
/// Shown on the side opposite to [ChatConfiguration.senderAlignment], with
/// [BubbleConfiguration.receiverBubbleBuilder] and
/// [BubbleConfiguration.receiverProfileBuilder]. Receiver messages cannot
/// fail, so [isFailed] is always `false`.
///
/// Add received messages with [ChatController.addMessage], or with
/// [ChatController.dispatchMessage] to let [Chat] auto-scroll or show
/// [ChatConfiguration.newReceiveMessageNotificationBuilder]:
///
/// ```dart
/// final message = ReceiverMessage(
///   id: dto.id,
///   name: dto.author,
///   timestamp: dto.sentAt, // e.g. '2026-01-31T09:30:00Z'
///   elements: [TextElement(dto.text)],
///   isRead: dto.isRead,
/// );
/// controller.addMessage(message);
/// ```
class ReceiverMessage extends Message {
  /// Creates a [ReceiverMessage].
  ///
  /// An [id] is required: use the id your server assigned to the message.
  ReceiverMessage({
    required super.timestamp,
    required super.name,
    required super.elements,
    super.isLoading,
    required super.id,
    super.serverUuid,
    super.width,
    super.isRead,
  });

  /// Returns a copy of this message with the given fields replaced.
  ///
  /// `isFailed` is ignored, since receiver messages cannot fail. [name] and
  /// [serverUuid] are kept.
  @override
  ReceiverMessage copyWith({
    String? id,
    bool? isLoading,
    List<MessageElement>? elements,
    bool? isFailed,
    bool? isRead,
    String? timestamp,
    double? width,
  }) {
    final copy = ReceiverMessage(
      name: name,
      timestamp: timestamp ?? this.timestamp,
      elements: elements ?? this.elements,
      isLoading: isLoading ?? this.isLoading,
      id: id ?? this.id,
      serverUuid: serverUuid,
      width: width ?? this.width,
      isRead: isRead ?? this.isRead,
    );
    return copy;
  }
}

/// A message sent by the current user.
///
/// Shown on the [ChatConfiguration.senderAlignment] side, with
/// [BubbleConfiguration.senderBubbleBuilder] and
/// [BubbleConfiguration.senderProfileBuilder]. Send it with
/// [ChatController.dispatchMessage] to get loading, failure and retry
/// handling, or add an already sent one (e.g. from history) with
/// [ChatController.setMessages] or [ChatController.addMessage].
///
/// ```dart
/// await controller.dispatchMessage(
///   SenderMessage(
///     name: 'Me',
///     timestamp: DateTime.now().toIso8601String(),
///     elements: [TextElement(text)],
///   ),
///   onDispatch: sendToServer,
/// );
/// ```
class SenderMessage extends Message {
  /// Creates a [SenderMessage].
  ///
  /// When [id] is omitted, a random UUID v4 is generated, so a message being
  /// composed can be tracked before your server assigns its own id (keep
  /// that one in [serverUuid], or return a copy with a new [id] from the
  /// [MessageDispatchCallback]).
  SenderMessage({
    required super.timestamp,
    required super.name,
    required super.elements,
    super.isLoading,
    super.isFailed,
    super.isRead,
    String? id,
    super.serverUuid,
    super.width,
  }) : super(id: id ?? const Uuid().v4());

  /// Returns a copy of this message with the given fields replaced.
  ///
  /// [name] and [serverUuid] are kept.
  @override
  SenderMessage copyWith({
    String? id,
    bool? isLoading,
    List<MessageElement>? elements,
    bool? isFailed,
    bool? isRead,
    String? timestamp,
    double? width,
  }) {
    return SenderMessage(
      id: id ?? this.id,
      serverUuid: serverUuid,
      timestamp: timestamp ?? this.timestamp,
      elements: elements ?? this.elements,
      isLoading: isLoading ?? this.isLoading,
      isFailed: isFailed ?? this.isFailed,
      name: name,
      width: width ?? this.width,
      isRead: isRead ?? this.isRead,
    );
  }
}
