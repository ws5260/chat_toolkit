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

  /// Language of the generated messages ('en', 'ko', 'ja' or 'zh').
  String language = 'en';

  /// Name of the other person in every room.
  String get otherName => switch (language) {
    'ko' => '민지',
    'ja' => 'さくら',
    'zh' => '小雨',
    _ => 'Alex',
  };

  /// Name of the user.
  String get myName => switch (language) {
    'ko' => '나',
    'ja' => '自分',
    'zh' => '我',
    _ => 'Me',
  };

  // Fixed per app run so timestamps stay stable between page loads.
  final DateTime _now = DateTime.now();

  // Messages sent or received in a room after its generated history, kept so they are still
  // there when the room is reloaded (e.g. back from a search result).
  final Map<String, List<Message>> _posted = {};

  /// Number of messages in [room]: its generated history plus [post]ed messages.
  int countOf(RoomInfo room) => room.totalMessages + (_posted[room.id]?.length ?? 0);

  Message _at(RoomInfo room, int index) => index < room.totalMessages
      ? _message(room, index)
      : _posted[room.id]![index - room.totalMessages];

  /// Stores a message sent or received in [room] after its history.
  void post(RoomInfo room, Message message) => (_posted[room.id] ??= []).add(message);

  /// Returns up to [pageSize] messages older than [beforeIndex] (all newest when `null`),
  /// newest first — the order [ChatController.appendMessages] expects.
  Future<List<Message>> fetchMessages(RoomInfo room, {int? beforeIndex}) async {
    await Future<void>.delayed(room.latency);
    final end = beforeIndex ?? countOf(room); // exclusive
    final start = max(0, end - pageSize);
    return [for (var i = end - 1; i >= start; i--) _at(room, i)];
  }

  /// Returns up to [pageSize] messages newer than [afterIndex], oldest first — the order
  /// [ChatController.addNewerMessages] expects — and whether even newer ones exist.
  Future<({List<Message> messages, bool hasMore})> fetchNewer(
    RoomInfo room, {
    required int afterIndex,
  }) async {
    await Future<void>.delayed(room.latency);
    final count = countOf(room);
    final end = min(count, afterIndex + 1 + pageSize);
    return (
      messages: [for (var i = afterIndex + 1; i < end; i++) _at(room, i)],
      hasMore: end < count,
    );
  }

  /// Returns the messages around [index] (half a page on each side), for
  /// [ChatController.setMessagesAround].
  Future<({List<Message> messages, bool hasOlder, bool hasNewer})> fetchAround(
    RoomInfo room,
    int index,
  ) async {
    await Future<void>.delayed(room.latency);
    final count = countOf(room);
    final start = max(0, index - pageSize ~/ 2);
    final end = min(count, index + pageSize ~/ 2 + 1);
    return (
      messages: [for (var i = start; i < end; i++) _at(room, i)],
      hasOlder: start > 0,
      hasNewer: end < count,
    );
  }

  /// Indices of the text messages in [room] containing [query] (case-insensitive), newest first,
  /// each repeated once per match so the search steps through the matches one at a time.
  Future<List<int>> search(RoomInfo room, String query) async {
    await Future<void>.delayed(room.latency);
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return [
      for (var i = countOf(room) - 1; i >= 0; i--)
        for (final e in _at(room, i).elements.whereType<DemoTextElement>())
          for (var k = 0; k < _countMatches(e.text.toLowerCase(), needle); k++) i,
    ];
  }

  // Non-overlapping, like SearchHighlightedText marks them.
  static int _countMatches(String text, String needle) {
    var count = 0;
    for (var i = text.indexOf(needle); i >= 0; i = text.indexOf(needle, i + needle.length)) {
      count++;
    }
    return count;
  }

  /// Id of the message at [index] in [room].
  String idAt(RoomInfo room, int index) => _at(room, index).id;

  /// Index of [message] in [room], or `null` when the server does not have it.
  int? indexIn(RoomInfo room, Message message) => indexOfId(room, message.id);

  /// Index of the message with [id] in [room], or `null` when the server does not have it.
  int? indexOfId(RoomInfo room, String id) {
    final posted = _posted[room.id]?.indexWhere((m) => m.id == id) ?? -1;
    if (posted >= 0) return room.totalMessages + posted;
    if (!id.startsWith('${room.id}_')) return null;
    return int.tryParse(id.substring(id.lastIndexOf('_') + 1));
  }

  /// A message pushed by the server (e.g. over a socket).
  Message incomingMessage(RoomInfo room, int count) => ReceiverMessage(
    id: '${room.id}_in_${DateTime.now().microsecondsSinceEpoch}',
    name: otherName,
    timestamp: DateTime.now().toIso8601String(),
    elements: [
      DemoTextElement(switch (language) {
        'ko' => '새로 도착한 메시지 $count',
        'ja' => '新着メッセージ $count',
        'zh' => '新消息 $count',
        _ => 'New message $count',
      }),
    ],
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
    'ja': [
      'うん',
      'いいね！',
      '今週末、時間ある？',
      '駅の近くに新しくできたラーメン屋さん、行ってみない？',
      '借りてた本、さっき読み終わったよ。結末が全然予想と違ったから、今度会ったときに感想を聞かせてね。',
      'あはは、私も',
      '何時がいい？',
    ],
    'zh': [
      '嗯',
      '好啊！',
      '这个周末有空吗？',
      '车站附近新开了一家面馆，要不要去试试？',
      '你借我的书我刚看完了。结局和我想的完全不一样，下次见面时想听听你的看法。',
      '哈哈，我也是',
      '几点方便？',
    ],
  };

  List<String> get _texts => _textsByLanguage[language] ?? _textsByLanguage['en']!;

  Message _message(RoomInfo room, int index) {
    final random = Random(room.id.hashCode ^ index);
    // Zero-padded so ids sort in message order (used as customSortCallback).
    final id = '${room.id}_${index.toString().padLeft(6, '0')}';
    // 6 messages a day, 7 minutes apart, so a screen of messages shows date separators.
    final age = room.totalMessages - index;
    final timestamp = _now
        .subtract(Duration(days: age ~/ 6, minutes: 7 * (age % 6)))
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
        // Read by the other person, so a read indicator shows on old messages too.
        ? SenderMessage(
            id: id, name: myName, timestamp: timestamp, elements: elements, isRead: true)
        : ReceiverMessage(id: id, name: otherName, timestamp: timestamp, elements: elements);
  }
}

class DemoTextElement extends MessageElement {
  const DemoTextElement(this.text);
  final String text;

  // Marks the query while the chat's search is open.
  @override
  Widget toWidget(BuildContext context) => SearchHighlightedText(text);

  // The summary for Message.previewText, e.g. in a new message notice.
  @override
  String get previewText => text;

  @override
  DemoTextElement copyWith() => DemoTextElement(text);
}

/// Image that loads after [loadDelay]: a small placeholder first, then the bubble grows to
/// [height]. Like a cached network image, it shows at full size right away once loaded.
class DemoImageElement extends MessageElement {
  const DemoImageElement({required this.key, required this.height, required this.loadDelay});

  final String key;
  final double height;
  final Duration loadDelay;

  @override
  Widget toWidget(BuildContext context) =>
      _DemoImage(key: ValueKey(key), cacheKey: key, height: height, loadDelay: loadDelay);

  @override
  String get previewText => switch (FakeChatServer.instance.language) {
        'ko' => '사진',
        'ja' => '写真',
        'zh' => '图片',
        _ => 'Photo',
      };

  @override
  DemoImageElement copyWith() => DemoImageElement(key: key, height: height, loadDelay: loadDelay);
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
          child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return Container(
      width: 200,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.primaries[widget.cacheKey.hashCode % Colors.primaries.length].shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text('이미지 ${widget.height.toInt()}px'),
    );
  }
}
