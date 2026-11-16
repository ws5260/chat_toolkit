import 'dart:math';

import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';

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
    title: '짧은 방',
    description: '메시지 5건. 화면을 다 채우지 못함',
    totalMessages: 5,
  ),
  RoomInfo(
    id: 'normal',
    title: '보통 방',
    description: '메시지 60건. 30건씩 2페이지',
    totalMessages: 60,
  ),
  RoomInfo(
    id: 'long',
    title: '긴 방',
    description: '메시지 500건. 위로 스크롤하면 30건씩 계속 불러옴',
    totalMessages: 500,
  ),
  RoomInfo(
    id: 'images',
    title: '이미지 많은 방',
    description: '메시지 120건 중 40%가 이미지. 이미지가 늦게 로드되며 말풍선이 커짐',
    totalMessages: 120,
    imageRatio: 0.4,
  ),
  RoomInfo(
    id: 'slow',
    title: '느린 서버 방',
    description: '메시지 200건. 서버 응답 2초',
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
        name: '상담사',
        timestamp: DateTime.now().toIso8601String(),
        elements: [DemoTextElement('새로 도착한 메시지 $count')],
      );

  /// Index of a message created by this server, from its id; `null` for other messages.
  static int? indexOf(Message message) {
    final i = message.id.lastIndexOf('_');
    return i < 0 ? null : int.tryParse(message.id.substring(i + 1));
  }

  static const List<String> _texts = [
    '네',
    '확인했습니다.',
    '안녕하세요, 문의 주셔서 감사합니다.',
    '말씀하신 내용 확인 후 다시 연락드리겠습니다. 잠시만 기다려 주세요.',
    '주문하신 상품은 오늘 출고될 예정이며, 배송 조회는 문자로 안내된 링크에서 확인하실 수 있습니다. 추가로 궁금하신 점이 있으면 언제든 말씀해 주세요.',
    '감사합니다!',
    '혹시 주문번호를 알려주실 수 있을까요?',
  ];

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
        ? SenderMessage(id: id, name: '나', timestamp: timestamp, elements: elements)
        : ReceiverMessage(id: id, name: '상담사', timestamp: timestamp, elements: elements);
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
