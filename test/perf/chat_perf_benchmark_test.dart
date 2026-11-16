// Baseline performance benchmark for ChatController / Chat.
//
// Run:  flutter test test/perf/chat_perf_benchmark_test.dart --reporter expanded
//
// flutter test runs in JIT/debug mode, so absolute numbers are not production
// numbers. Use them to compare before/after on the same machine.
import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TextElement extends MessageElement {
  const _TextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) => Text(text);

  @override
  _TextElement copyWith() => _TextElement(text);
}

final _base = DateTime.utc(2026, 1, 1, 9);

/// Builds [count] messages starting at [startIndex], 90 seconds apart
/// (10k messages span ~10 days, so date dividers appear), switching side
/// every 5 messages so groups are realistic.
List<Message> _makeMessages(int count, {int startIndex = 0}) {
  return List<Message>.generate(count, (j) {
    final i = startIndex + j;
    final ts = _base.add(Duration(seconds: 90 * i)).toIso8601String();
    final elements = <MessageElement>[_TextElement('message $i')];
    return (i ~/ 5).isEven
        ? SenderMessage(id: 'm$i', name: 'me', timestamp: ts, elements: elements)
        : ReceiverMessage(
            id: 'm$i', name: 'other', timestamp: ts, elements: elements);
  });
}

/// Runs [body] [runs] times after [warmup] runs and prints median / min.
void _bench(String label, int runs, void Function() body, {int warmup = 2}) {
  for (var i = 0; i < warmup; i++) {
    body();
  }
  final samples = <int>[];
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    body();
    sw.stop();
    samples.add(sw.elapsedMicroseconds);
  }
  samples.sort();
  final median = samples[samples.length ~/ 2] / 1000;
  final min = samples.first / 1000;
  // ignore: avoid_print
  print('[PERF] $label: median ${median.toStringAsFixed(2)} ms, '
      'min ${min.toStringAsFixed(2)} ms (n=$runs)');
}

void main() {
  group('ChatController (logic only)', () {
    for (final n in [1000, 10000]) {
      test('setMessages $n', () {
        final source = _makeMessages(n);
        _bench('setMessages n=$n (shuffled input)', n >= 10000 ? 3 : 10, () {
          final controller = ChatController();
          final input = List<Message>.of(source)..shuffle();
          controller.setMessages(input);
          controller.dispose();
        }, warmup: 1);
      });

      test('addMessage 1 into $n', () {
        final controller = ChatController()..setMessages(_makeMessages(n));
        var next = n;
        _bench('addMessage 1 new message into n=$n', 50, () {
          controller.addMessage(_makeMessages(1, startIndex: next++).single);
        });
        controller.dispose();
      });

      test('containsMessageId miss on $n', () {
        final controller = ChatController()..setMessages(_makeMessages(n));
        _bench('containsMessageId (miss) n=$n', 50, () {
          controller.containsMessageId('not-exist');
        });
        controller.dispose();
      });
    }

    test('appendMessages page of 50 onto 10000', () {
      // Older messages use negative indices so they precede the loaded ones.
      final page = _makeMessages(50, startIndex: -50).reversed.toList();
      // Prepare controllers up front so only appendMessages is timed.
      final loaded = _makeMessages(10000);
      final controllers = List.generate(
          11, (_) => ChatController()..setMessages(List.of(loaded)));
      var k = 0;
      _bench('appendMessages 50 onto n=10000', 10, () {
        controllers[k++].appendMessages(page);
      }, warmup: 1);
      for (final c in controllers) {
        c.dispose();
      }
    });
  });

  group('Chat widget (build)', () {
    for (final n in [1000, 10000]) {
      testWidgets('receive 1 message with $n loaded', (tester) async {
        final controller = ChatController()..setMessages(_makeMessages(n));
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: Chat(chatController: controller)),
        ));
        await tester.pumpAndSettle();

        final samples = <int>[];
        for (var i = 0; i < 20; i++) {
          final sw = Stopwatch()..start();
          controller.addMessage(_makeMessages(1, startIndex: n + i).single);
          await tester.pump();
          sw.stop();
          samples.add(sw.elapsedMicroseconds);
        }
        samples.sort();
        // ignore: avoid_print
        print('[PERF] receive 1 message + pump, n=$n: median '
            '${(samples[samples.length ~/ 2] / 1000).toStringAsFixed(2)} ms');

        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      });
    }
  });
}
