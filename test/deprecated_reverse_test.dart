// ignore_for_file: deprecated_member_use_from_same_package
import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reverse is still accepted but ignored', () {
    for (final value in [true, false, null]) {
      final c = ChatController(reverse: value);
      expect(c.reverse, isTrue);
      c.dispose();
    }
  });
}
