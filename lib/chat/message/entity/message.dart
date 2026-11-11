import '../elements/message_element.dart';
import 'package:uuid/uuid.dart';

/// Base class for a single chat message.
///
/// Use [SenderMessage] for messages sent by the current user and
/// [ReceiverMessage] for messages from other participants. The content of a
/// message is a list of [MessageElement]s, which you implement for each
/// content type (text, image, file, ...).
abstract class Message {
  /// Unique identifier of the message.
  ///
  /// Used to find, update and deduplicate messages in [ChatController].
  /// Adding a message whose id already exists replaces the existing one.
  final String id;

  /// Optional identifier assigned by your server.
  ///
  /// Not used by the toolkit itself; keep it here to map local messages to
  /// server records.
  final String? serverUuid;

  /// Time the message was sent, as a string parsable by [DateTime.parse]
  /// (e.g. ISO 8601).
  ///
  /// Used for ordering, grouping consecutive messages and date separators.
  final String timestamp;

  /// Display name of the author.
  ///
  /// Consecutive messages from the same author within the same minute are
  /// grouped, and the name is passed to the profile builders.
  final String name;

  /// Content of the message, rendered in order inside one bubble.
  final List<MessageElement> elements;

  /// Whether the message is still being sent.
  ///
  /// While `true`, [BubbleConfiguration.loadingWidget] is shown in the bubble.
  final bool isLoading;

  /// Whether sending the message failed.
  ///
  /// Failed sender messages show retry and delete buttons.
  final bool isFailed;

  /// Read state of the message.
  ///
  /// `null` means read state is not tracked for this message, so no read
  /// indicator is shown. See [BubbleConfiguration.readIndicatorBuilder] and
  /// [ChatController.updateMessageAllRead].
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

  /// Returns a copy of this message with the given fields replaced.
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
/// Receiver messages cannot fail, so [isFailed] is always `false`.
class ReceiverMessage extends Message {
  /// Creates a [ReceiverMessage]. An [id] is required.
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
/// Send it with [ChatController.dispatchMessage] to get loading, failure and
/// retry handling.
class SenderMessage extends Message {
  /// Creates a [SenderMessage].
  ///
  /// When [id] is omitted, a random UUID v4 is generated.
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
