import 'package:chat_toolkit/chat/message/elements/message_element.dart';
import 'package:uuid/uuid.dart';

abstract class Message {
  final String id;
  final String timestamp;
  final String name;

  final List<MessageElement> elements;
  final bool isLoading;
  final bool isFailed;
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

  bool get isSender => this is SenderMessage;

  Message copyWith({
    String? timestamp,
    bool? isLoading,
    List<MessageElement>? elements,
    bool? isFailed,
    double? width,
  });
}

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
