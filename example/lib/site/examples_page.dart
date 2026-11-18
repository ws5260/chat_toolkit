import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../rooms/fake_chat_server.dart';
import '../rooms/room_chat_screen.dart';
import 'site_locale.dart';
import 'site_theme.dart';

/// The example rooms. Wide screens show the selected room in a large card next to the list;
/// narrow screens open it full screen.
class ExamplesPage extends StatefulWidget {
  const ExamplesPage({super.key});

  @override
  State<ExamplesPage> createState() => _ExamplesPageState();
}

class _ExamplesPageState extends State<ExamplesPage> {
  String _selected = demoRooms[1].id;
  int _openCount = 0; // re-opens the room on every tap

  Widget _roomScreen(String id) =>
      RoomChatScreen(room: demoRooms.firstWhere((r) => r.id == id));

  void _open(String id, bool wide) {
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
    final language = Localizations.localeOf(context).languageCode;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1024;
      final list = _list(wide);
      if (!wide) return list;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: 440, child: list),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 28, 28, 28),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: SiteShadows.card,
                  ),
                  child: KeyedSubtree(
                    // Reopen the room when its options or the language change.
                    key: ValueKey('$_selected/$_openCount/$language'),
                    child: _roomScreen(_selected),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }

  Widget _list(bool wide) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 16, 48),
      children: [
        Text(l.navExamples, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(l.examplesIntro,
            style: const TextStyle(fontSize: 15, color: SiteColors.grey600, height: 1.6)),
        const SizedBox(height: 24),
        SiteCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            for (final room in demoRooms)
              _RoomRow(
                key: ValueKey('room-${room.id}'),
                title: roomTitle(l, room.id),
                subtitle: roomDescription(l, room.id),
                trailing: l.seconds((room.latency.inMilliseconds / 1000).toStringAsFixed(1)),
                selected: wide && _selected == room.id,
                onTap: () => _open(room.id, wide),
              ),
          ]),
        ),
      ],
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
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
                  child: Icon(Icons.forum_rounded,
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
                Text(trailing, style: const TextStyle(fontSize: 13, color: SiteColors.grey500)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: SiteColors.grey400),
              ]),
            ),
          ),
        ),
      );
}
