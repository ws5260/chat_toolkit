import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Text extends MessageElement {
  const _Text(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) => Text(text);

  @override
  String get previewText => text;

  @override
  _Text copyWith() => _Text(text);
}

class _Photo extends MessageElement {
  const _Photo({this.preview});
  final String? preview;

  @override
  Widget toWidget(BuildContext context) => const SizedBox();

  @override
  String? get previewText => preview;

  @override
  _Photo copyWith() => _Photo(preview: preview);
}

/// An element that does not override previewText.
class _Plain extends MessageElement {
  const _Plain();

  @override
  Widget toWidget(BuildContext context) => const SizedBox();

  @override
  _Plain copyWith() => const _Plain();
}

Message _message(List<MessageElement> elements) =>
    ReceiverMessage(id: 'm', name: 'Alex', timestamp: '2026-01-01T00:00:00', elements: elements);

void main() {
  test('previewText joins the previews of the elements', () {
    expect(
      _message(const [_Photo(preview: 'Photo'), _Text('Look at\nthis  view')]).previewText,
      'Photo Look at this view',
    );
  });

  test('elements without a preview are left out', () {
    expect(_message(const [_Plain(), _Photo(), _Text('Hi')]).previewText, 'Hi');
    expect(_message(const [_Plain(), _Text('  ')]).previewText, '');
    expect(const _Plain().previewText, isNull);
  });
}
