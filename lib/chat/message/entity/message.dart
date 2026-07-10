import 'package:uuid/uuid.dart';

import '../elements/message_element.dart';

abstract class Message {
  final String id;
  final String timestamp;
  final String name;

  final List<MessageElement> elements;
  final bool isLoading;
  final bool isFailed;
  final bool? isRead;
  final double? width;

  Message({
    required this.name,
    required this.id,
    required this.timestamp,
    required this.elements,
    this.isLoading = false,
    this.isFailed = false,
    this.isRead,
    this.width,
  });

  bool get isSender => this is SenderMessage;

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

class ReceiverMessage extends Message {
  ReceiverMessage({
    required super.timestamp,
    required super.name,
    required super.elements,
    super.isLoading,
    required super.id,
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
      width: width ?? this.width,
      isRead: isRead ?? this.isRead,
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
    super.isRead,
    String? id,
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
