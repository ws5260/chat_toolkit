import 'dart:math';

import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:material_ui/material_ui.dart';

/// A chat room served by [FakeChatServer].
class RoomInfo {
  const RoomInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.totalMessages,
    this.latency = const Duration(milliseconds: 600),
    this.imageRatio = 0,
  });

  final String id;
  final String title;
  final String description;

  /// Messages the server holds for this room. Loaded in pages of [FakeChatServer.pageSize].
  final int totalMessages;

  /// Delay of every server response.
  final Duration latency;

  /// Share of messages (0..1) that contain an image which loads late and grows the bubble.
  final double imageRatio;
}

const List<RoomInfo> demoRooms = [
  RoomInfo(
    id: 'short',
    title: 'Short room',
    description: '5 messages, not enough to fill the screen',
    totalMessages: 5,
  ),
  RoomInfo(
    id: 'normal',
    title: 'Normal room',
    description: '60 messages in 2 pages of 30',
    totalMessages: 60,
  ),
  RoomInfo(
    id: 'long',
    title: 'Long room',
    description: '500 messages, 30 more at a time when scrolled up',
    totalMessages: 500,
  ),
  RoomInfo(
    id: 'images',
    title: 'Image room',
    description: '120 messages, 40% images that load late and grow',
    totalMessages: 120,
    imageRatio: 0.4,
  ),
  RoomInfo(
    id: 'slow',
    title: 'Slow server',
    description: '200 messages, 2-second responses',
    totalMessages: 200,
    latency: Duration(seconds: 2),
    imageRatio: 0.15,
  ),
];

/// Simulates a chat API: pages of messages, newest first, after [RoomInfo.latency].
class FakeChatServer {
  FakeChatServer._();
  static final FakeChatServer instance = FakeChatServer._();

  static const int pageSize = 30;

  /// Language of the generated messages ('en' or 'ko').
  String language = 'en';

  /// Name of the other person in every room.
  String get otherName => language == 'ko' ? '민지' : 'Alex';

  /// Name of the user.
  String get myName => language == 'ko' ? '나' : 'Me';

  // Fixed per app run so timestamps stay stable between page loads.
  final DateTime _now = DateTime.now();

  /// Returns up to [pageSize] messages older than [beforeIndex] (all newest when `null`),
  /// newest first — the order [ChatController.appendMessages] expects.
  Future<List<Message>> fetchMessages(RoomInfo room, {int? beforeIndex}) async {
    await Future<void>.delayed(room.latency);
    final end = beforeIndex ?? room.totalMessages; // exclusive
    final start = max(0, end - pageSize);
    return [for (var i = end - 1; i >= start; i--) _message(room, i)];
  }

  /// A message pushed by the server (e.g. over a socket).
  Message incomingMessage(RoomInfo room, int count) => ReceiverMessage(
        id: '${room.id}_in_${DateTime.now().microsecondsSinceEpoch}',
        name: otherName,
        timestamp: DateTime.now().toIso8601String(),
        elements: [DemoTextElement(language == 'ko' ? '새로 도착한 메시지 $count' : 'New message $count')],
      );

  /// Index of a message created by this server, from its id; `null` for other messages.
  static int? indexOf(Message message) {
    final i = message.id.lastIndexOf('_');
    return i < 0 ? null : int.tryParse(message.id.substring(i + 1));
  }

  static const Map<String, List<String>> _textsByLanguage = {
    'en': [
      'Sure',
      'Sounds good!',
      'Are you free this weekend?',
      'I was thinking we could try that new noodle place near the station.',
      'I just finished the book you lent me. The ending was not what I expected at all, so I want to hear what you thought about it next time we meet.',
      'Haha, same here',
      'What time works for you?',
    ],
    'ko': [
      '응',
      '좋아!',
      '이번 주말에 시간 돼?',
      '역 근처에 새로 생긴 국숫집 가 보면 어떨까 해.',
      '빌려준 책 방금 다 읽었어. 결말이 생각이랑 완전히 달라서, 다음에 만나면 네 생각도 듣고 싶어.',
      'ㅋㅋ 나도',
      '몇 시가 괜찮아?',
    ],
  };

  List<String> get _texts => _textsByLanguage[language] ?? _textsByLanguage['en']!;

  Message _message(RoomInfo room, int index) {
    final random = Random(room.id.hashCode ^ index);
    // Zero-padded so ids sort in message order (used as customSortCallback).
    final id = '${room.id}_${index.toString().padLeft(6, '0')}';
    final timestamp = _now
        .subtract(Duration(minutes: 7 * (room.totalMessages - index)))
        .toIso8601String();
    final elements = <MessageElement>[
      if (random.nextDouble() < room.imageRatio)
        DemoImageElement(
          key: id,
          height: 120 + random.nextInt(160).toDouble(),
          loadDelay: Duration(milliseconds: 300 + random.nextInt(1200)),
        )
      else
        DemoTextElement('#$index ${_texts[random.nextInt(_texts.length)]}'),
    ];
    // Runs of 3 messages per side.
    final isSender = (index ~/ 3).isOdd;
    return isSender
        ? SenderMessage(id: id, name: myName, timestamp: timestamp, elements: elements)
        : ReceiverMessage(id: id, name: otherName, timestamp: timestamp, elements: elements);
  }
}

class DemoTextElement extends MessageElement {
  const DemoTextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) => Text(text);

  @override
  DemoTextElement copyWith() => DemoTextElement(text);
}

/// Image that loads after [loadDelay]: a small placeholder first, then the bubble grows to
/// [height]. Like a cached network image, it shows at full size right away once loaded.
class DemoImageElement extends MessageElement {
  const DemoImageElement({
    required this.key,
    required this.height,
    required this.loadDelay,
  });

  final String key;
  final double height;
  final Duration loadDelay;

  @override
  Widget toWidget(BuildContext context) =>
      _DemoImage(key: ValueKey(key), cacheKey: key, height: height, loadDelay: loadDelay);

  @override
  DemoImageElement copyWith() =>
      DemoImageElement(key: key, height: height, loadDelay: loadDelay);
}

class _DemoImage extends StatefulWidget {
  const _DemoImage({
    super.key,
    required this.cacheKey,
    required this.height,
    required this.loadDelay,
  });

  final String cacheKey;
  final double height;
  final Duration loadDelay;

  static final Set<String> _loaded = {};

  @override
  State<_DemoImage> createState() => _DemoImageState();
}

class _DemoImageState extends State<_DemoImage> {
  late bool _loaded = _DemoImage._loaded.contains(widget.cacheKey);

  @override
  void initState() {
    super.initState();
    if (_loaded) return;
    Future<void>.delayed(widget.loadDelay, () {
      _DemoImage._loaded.add(widget.cacheKey);
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        width: 200,
        height: 48,
        child: Center(
          child: SizedBox.square(
              dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return Container(
      width: 200,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.primaries[widget.cacheKey.hashCode % Colors.primaries.length]
            .shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text('이미지 ${widget.height.toInt()}px'),
    );
  }
}
