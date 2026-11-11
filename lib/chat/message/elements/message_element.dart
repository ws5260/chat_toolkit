import 'package:flutter/material.dart';

/// A piece of content inside a [Message], such as text, an image or a file.
///
/// Extend this class for each content type your chat supports:
///
/// ```dart
/// class TextElement extends MessageElement {
///   const TextElement(this.text);
///   final String text;
///
///   @override
///   Widget toWidget(BuildContext context) => Text(text);
///
///   @override
///   TextElement copyWith() => TextElement(text);
/// }
/// ```
abstract class MessageElement {
  /// Const constructor for subclasses.
  const MessageElement();

  /// Builds the widget for this element, shown inside the message bubble.
  Widget toWidget(BuildContext context);

  /// Returns a copy of this element.
  MessageElement copyWith();
}
