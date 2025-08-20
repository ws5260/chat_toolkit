import 'package:chat_toolkit/chat/message/elements/message_element.dart';
import 'package:uuid/uuid.dart';

export 'package:chat_toolkit/chat/message/entity/failed_message_entry.dart';
export 'package:chat_toolkit/chat/message/elements/message_element.dart';
export 'package:chat_toolkit/chat/message/entity/message_group.dart';

/// Abstract base class representing a chat message.
///
/// This class follows the Template Method pattern by defining the common
/// structure and behavior for all message types while allowing specific
/// implementations for different message directions (sender/receiver).
///
/// Key features:
/// - Unique identification and timestamp tracking
/// - Element-based content structure for rich messages
/// - Loading and failure state management
/// - Immutable message copying with state updates
///
/// See also:
/// * [SenderMessage] for outgoing messages
/// * [ReceiverMessage] for incoming messages
/// * [MessageElement] for rich content structure
abstract class Message {
  /// Unique identifier for this message.
  final String id;

  /// ISO 8601 timestamp when the message was created.
  final String timestamp;

  /// Display name of the message author.
  final String name;

  /// List of content elements that make up the message.
  ///
  /// This allows for rich messages with multiple types of content
  /// (text, images, etc.) following the Composite pattern.
  final List<MessageElement> elements;

  /// Whether the message is currently in a loading state.
  ///
  /// Typically true while the message is being sent or processed.
  final bool isLoading;

  /// Whether the message failed to send or process.
  final bool isFailed;

  /// Optional width constraint for the message bubble.
  final double? width;

  Message({
    required this.name,
    required this.id,
    required this.timestamp,
    required this.elements,
    this.isLoading = false,
    this.isFailed = false,
    this.width,
  });

  /// Whether this message is from the sender.
  ///
  /// This is determined by the concrete type of the message instance.
  bool get isSender => this is SenderMessage;

  /// Creates a copy of this message with updated properties.
  ///
  /// This method supports the Immutable Object pattern by allowing
  /// state updates without modifying the original instance.
  Message copyWith({
    String? timestamp,
    bool? isLoading,
    List<MessageElement>? elements,
    bool? isFailed,
    double? width,
  });
}

/// Represents an incoming message from another participant.
///
/// This class implements the concrete behavior for messages received
/// from other users in the chat. It maintains immutability while
/// supporting state updates through the copyWith method.
class ReceiverMessage extends Message {
  ReceiverMessage({
    required super.timestamp,
    required super.name,
    required super.elements,
    super.isLoading,
    required super.id,
    super.width,
  });

  @override
  ReceiverMessage copyWith({
    bool? isLoading,
    List<MessageElement>? elements,
    bool? isFailed,
    String? timestamp,
    double? width,
  }) {
    final copy = ReceiverMessage(
      name: name,
      timestamp: timestamp ?? this.timestamp,
      elements: elements ?? this.elements,
      isLoading: isLoading ?? this.isLoading,
      id: id,
      width: width ?? this.width,
    );
    return copy;
  }
}

/// Represents an outgoing message from the current user.
///
/// This class handles messages sent by the current user, including
/// automatic UUID generation for unique identification. It supports
/// failure states for retry functionality.
class SenderMessage extends Message {
  SenderMessage({
    required super.timestamp,
    required super.name,
    required super.elements,
    super.isLoading,
    super.isFailed,
    String? id,
    super.width,
  }) : super(id: id ?? const Uuid().v4());

  @override
  SenderMessage copyWith({
    bool? isLoading,
    List<MessageElement>? elements,
    bool? isFailed,
    String? timestamp,
    double? width,
  }) {
    return SenderMessage(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      elements: elements ?? this.elements,
      isLoading: isLoading ?? this.isLoading,
      isFailed: isFailed ?? this.isFailed,
      name: name,
      width: width ?? this.width,
    );
  }
}
