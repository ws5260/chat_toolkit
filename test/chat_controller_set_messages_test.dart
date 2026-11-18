import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:chat_toolkit/src/chat_controller.dart' show ChatControllerInternal;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _TextElement extends MessageElement {
  const _TextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) => Text(text);

  @override
  _TextElement copyWith() => _TextElement(text);
}

Message _msg(String id, DateTime time,
    {bool sender = false, String? name, bool? isRead, String text = ''}) {
  final ts = time.toIso8601String();
  final elements = [_TextElement(text.isEmpty ? id : text)];
  return sender
      ? SenderMessage(
          id: id,
          name: name ?? 'me',
          timestamp: ts,
          elements: elements,
          isRead: isRead)
      : ReceiverMessage(
          id: id,
          name: name ?? 'other',
          timestamp: ts,
          elements: elements,
          isRead: isRead);
}

/// Groups as (name, [ids / text]) for comparison.
List<String> _shape(ChatController c) => [
      for (final g in c.messageGroups)
        '${g.name}|${g.isSender}|${g.timestamp}|'
            '${g.messages.map((m) => '${m.id}:${(m.elements.single as _TextElement).text}').join(',')}',
    ];

int _sortById(Message a, Message b) => a.id.compareTo(b.id);

void main() {
  final t0 = DateTime(2026, 3, 1, 23, 58);

  List<Message> sample() => [
        _msg('a', t0, isRead: false),
        _msg('b', t0, isRead: true),
        _msg('c', t0.add(const Duration(seconds: 30)), sender: true),
        _msg('d', t0.add(const Duration(minutes: 1)), sender: true, isRead: false),
        // Same id as 'a', later in sorted order: replaces 'a' in place.
        _msg('a', t0.add(const Duration(minutes: 2)), text: 'a-updated'),
        _msg('', t0.add(const Duration(minutes: 3))),
        _msg('', t0.add(const Duration(minutes: 3))),
        _msg('e', t0.add(const Duration(minutes: 3)), name: 'someone'),
        _msg('f', t0.add(const Duration(days: 1))),
      ];

  void expectSameAsAddMessage(
      {CustomSortCallback? sort, AdditionalGroupCondition? condition}) {
    final input = sample()..shuffle();
    final viaSet = ChatController(
        customSortCallback: sort, additionalGroupCondition: condition)
      ..setMessages(List.of(input));

    // Reference: the unchanged addMessage path, fed the same sorted order.
    final sorted = List.of(input);
    ChatController(customSortCallback: sort).setMessages(sorted);
    final viaAdd = ChatController(
        customSortCallback: sort, additionalGroupCondition: condition);
    for (final m in sorted) {
      viaAdd.addMessage(m);
    }

    expect(_shape(viaSet), _shape(viaAdd));
    // Unread ids: updateMessageAllRead should mark the same messages.
    viaSet.updateMessageAllRead();
    viaAdd.updateMessageAllRead();
    expect(_shape(viaSet), _shape(viaAdd));
  }

  test('setMessages groups like addMessage one by one', () {
    for (var i = 0; i < 20; i++) {
      expectSameAsAddMessage(sort: _sortById);
    }
  });

  test('setMessages respects additionalGroupCondition', () {
    for (var i = 0; i < 20; i++) {
      expectSameAsAddMessage(
          sort: _sortById, condition: (g, m) => g.messages.isEmpty);
    }
  });

  test('setMessages sorts the given list in place', () {
    final input = sample().reversed.toList();
    ChatController(customSortCallback: _sortById).setMessages(input);
    for (var i = 1; i < input.length; i++) {
      expect(
          DateTime.parse(input[i - 1].timestamp)
              .isAfter(DateTime.parse(input[i].timestamp)),
          isFalse);
    }
  });

  test('setMessages notifies once', () {
    final c = ChatController();
    var count = 0;
    c.messagesRevision.addListener(() => count++);
    c.setMessages(sample());
    expect(count, 1);
  });

  testWidgets('date divider shows on the first group and on day changes',
      (tester) async {
    final c = ChatController()
      ..setMessages([
        _msg('1', DateTime(2026, 3, 1, 10)),
        _msg('2', DateTime(2026, 3, 1, 11), sender: true),
        _msg('3', DateTime(2026, 3, 2, 9)),
        _msg('4', DateTime(2026, 3, 2, 10), sender: true),
      ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Chat(
          chatController: c,
          configuration: ChatConfiguration(
            dateSeparatorBuilder: (context, ts) => Text('DIV $ts'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('DIV '), findsNWidgets(2));
    expect(find.text('DIV ${DateTime(2026, 3, 1, 10).toIso8601String()}'),
        findsOneWidget);
    expect(find.text('DIV ${DateTime(2026, 3, 2, 9).toIso8601String()}'),
        findsOneWidget);

    // A new day appended later also gets a divider.
    c.addMessage(_msg('5', DateTime(2026, 3, 3, 9)));
    await tester.pumpAndSettle();
    expect(find.textContaining('DIV '), findsNWidgets(3));

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  test('messageGroups and MessageGroup.messages are read-only views', () {
    final c = ChatController();
    c.setMessages([_msg('a', DateTime(2026, 3, 1, 10))]);
    final groups = c.messageGroups;
    expect(() => groups.clear(), throwsUnsupportedError);
    expect(() => groups.first.messages.clear(), throwsUnsupportedError);
    // The views reflect later changes.
    c.addMessage(_msg('b', DateTime(2026, 3, 1, 10)));
    expect(groups.first.messages.map((m) => m.id), ['a', 'b']);
    c.dispose();
  });

  test('retrying an unregistered message reports MessageNotRetryableException',
      () async {
    final c = ChatController();
    final results = <MessageDispatchResult>[];
    final sub = c.dispatchResultStream.listen(results.add);
    await c.retryMessage(_msg('x', DateTime(2026, 3, 1, 10), sender: true));
    await Future<void>.delayed(Duration.zero);
    expect(results.single.isSuccess, isFalse);
    expect(results.single.exception, isA<MessageNotRetryableException>());
    expect(
        (results.single.exception! as MessageNotRetryableException).messageId,
        'x');
    await sub.cancel();
    c.dispose();
  });
}
