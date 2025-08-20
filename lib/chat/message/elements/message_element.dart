import 'package:flutter/material.dart';

/// Abstract base class for message content elements.
///
/// This class implements the Strategy Pattern for message content rendering,
/// allowing different types of content (text, images, files, etc.) to be
/// displayed within messages while maintaining a consistent interface.
///
/// Each message element is responsible for:
/// - Converting itself to a displayable Widget
/// - Supporting immutable updates through copyWith
/// - Maintaining its own state and properties
///
/// Example implementation:
/// ```dart
/// class TextElement extends MessageElement {
///   final String text;
///
///   TextElement(this.text);
///
///   @override
///   Widget toWidget(BuildContext context) {
///     return Text(text);
///   }
///
///   @override
///   MessageElement copyWith() => TextElement(text);
/// }
/// ```
abstract class MessageElement {
  const MessageElement();

  /// Converts this element to a displayable Flutter widget.
  ///
  /// This method is called by the message rendering system to display
  /// the content. Implementations should return a widget appropriate
  /// for the element's content type.
  Widget toWidget(BuildContext context);

  /// Creates a copy of this element.
  ///
  /// This method supports the Immutable Object pattern by allowing
  /// element updates without modifying the original instance.
  MessageElement copyWith();
}
