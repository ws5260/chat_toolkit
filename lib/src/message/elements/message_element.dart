import 'package:material_ui/material_ui.dart';

/// A piece of content inside a [Message], such as text, an image or a file.
///
/// The toolkit has no built-in content types: extend this class for each
/// type your chat supports, and put instances in [Message.elements]. A
/// message's elements are rendered in order inside one bubble, which is
/// wrapped by [BubbleConfiguration.senderBubbleBuilder] or
/// [BubbleConfiguration.receiverBubbleBuilder] and limited to
/// [BubbleConfiguration.maxWidth] (or [Message.width]).
///
/// Elements should be immutable. To change the content of a shown message,
/// create the message again with new elements (see [Message.copyWith]) and
/// pass it to [ChatController.addMessage].
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
///
/// class ImageElement extends MessageElement {
///   const ImageElement({required this.url, this.caption});
///   final String url;
///   final String? caption;
///
///   @override
///   Widget toWidget(BuildContext context) => Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       ClipRRect(
///         borderRadius: BorderRadius.circular(8),
///         child: Image.network(url),
///       ),
///       if (caption != null) Text(caption!),
///     ],
///   );
///
///   @override
///   ImageElement copyWith({String? url, String? caption}) =>
///       ImageElement(url: url ?? this.url, caption: caption ?? this.caption);
/// }
///
/// final message = SenderMessage(
///   name: 'Me',
///   timestamp: DateTime.now().toIso8601String(),
///   elements: [const ImageElement(url: imageUrl), const TextElement('Look!')],
/// );
/// ```
abstract class MessageElement {
  /// Const constructor for subclasses.
  const MessageElement();

  /// Builds the widget for this element, shown inside the message bubble.
  ///
  /// Called whenever the bubble is built, which can happen often (for
  /// example while scrolling), so keep it cheap and side-effect free; return
  /// a [StatefulWidget] for content that loads or animates. Not called while
  /// the message's [Message.isLoading] is `true`. The bubble's width is
  /// bounded, its height is not.
  Widget toWidget(BuildContext context);

  /// Returns a copy of this element.
  ///
  /// Not called by the toolkit. Subclasses may narrow the return type and
  /// add optional parameters to replace fields, as in the example above.
  MessageElement copyWith();
}
