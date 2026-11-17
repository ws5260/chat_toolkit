import 'package:flutter/material.dart';

import 'fake_chat_server.dart';
import 'room_chat_screen.dart';

/// Lists the demo chat rooms. Each room loads its messages from [FakeChatServer] when opened,
/// to check how the list scrolls while server data arrives.
class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key, required this.demoScreenBuilder});

  /// Opens the original single-room demo (bubble menu, etc.).
  final WidgetBuilder demoScreenBuilder;

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Chat Toolkit Demo'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('서버에서 불러오는 채팅방', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final room in demoRooms)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.forum_outlined)),
              title: Text(room.title),
              subtitle: Text(
                  '${room.description}\n응답 ${room.latency.inMilliseconds}ms'),
              isThreeLine: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RoomChatScreen(room: room),
              )),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
            title: const Text('기본 데모'),
            subtitle: const Text('말풍선 메뉴, 자동 답장'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: widget.demoScreenBuilder)),
          ),
        ],
      ),
    );
  }
}
