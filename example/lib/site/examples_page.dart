import 'package:flutter/material.dart';

import '../rooms/fake_chat_server.dart';
import '../rooms/room_chat_screen.dart';
import 'site_theme.dart';

/// The example rooms. Wide screens show the selected room in a phone frame next to the list;
/// narrow screens open it full screen.
class ExamplesPage extends StatefulWidget {
  const ExamplesPage({super.key, required this.demoScreenBuilder});

  final WidgetBuilder demoScreenBuilder;

  @override
  State<ExamplesPage> createState() => _ExamplesPageState();
}

class _ExamplesPageState extends State<ExamplesPage> {
  bool _reverse = true;
  // A room id, or null for the single-room demo.
  String? _selected = demoRooms[1].id;
  int _openCount = 0; // re-opens the room on every tap

  Widget _roomScreen(String? id) {
    if (id == null) return widget.demoScreenBuilder(context);
    final room = demoRooms.firstWhere((r) => r.id == id);
    return RoomChatScreen(room: room, reverse: _reverse);
  }

  void _open(String? id, bool wide) {
    if (wide) {
      setState(() {
        _selected = id;
        _openCount++;
      });
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _roomScreen(id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1024;
      final list = _list(wide);
      if (!wide) return list;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: 460, child: list),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: PhoneFrame(
                    child: KeyedSubtree(
                      key: ValueKey('$_selected/$_reverse/$_openCount'),
                      child: _roomScreen(_selected),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }

  Widget _list(bool wide) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
        children: [
          Text('예제', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            '서버에서 메시지를 받아 오는 채팅방들이에요.\n방마다 메시지 수와 응답 속도가 달라서 스크롤 동작을 확인하기 좋아요.',
            style: TextStyle(fontSize: 15, color: SiteColors.grey600, height: 1.6),
          ),
          const SizedBox(height: 24),
          SiteCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('reverse',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('켜면 최신 메시지가 offset 0 이에요',
                      style: TextStyle(fontSize: 13, color: SiteColors.grey500)),
                ]),
              ),
              Switch(
                value: _reverse,
                onChanged: (v) => setState(() {
                  _reverse = v;
                  _openCount++;
                }),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SiteCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: [
              for (final room in demoRooms)
                _RoomRow(
                  title: room.title,
                  subtitle: room.description,
                  trailing: '${(room.latency.inMilliseconds / 1000).toStringAsFixed(1)}초',
                  selected: wide && _selected == room.id,
                  onTap: () => _open(room.id, wide),
                ),
              _RoomRow(
                title: '기본 데모',
                subtitle: '말풍선 메뉴와 자동 답장',
                icon: Icons.auto_awesome_rounded,
                selected: wide && _selected == null,
                onTap: () => _open(null, wide),
              ),
            ]),
          ),
        ],
      );
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.icon = Icons.forum_rounded,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: selected ? SiteColors.blueWeak : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : SiteColors.grey100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon,
                      size: 22, color: selected ? SiteColors.blue : SiteColors.grey600),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 13, color: SiteColors.grey500)),
                  ]),
                ),
                if (trailing != null)
                  Text(trailing!,
                      style: const TextStyle(fontSize: 13, color: SiteColors.grey500)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: SiteColors.grey400),
              ]),
            ),
          ),
        ),
      );
}
