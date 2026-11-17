import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../playground/playground_screen.dart';
import 'examples_page.dart';
import 'getting_started_page.dart';
import 'site_theme.dart';

const _version = '1.7.0';
final _pubUrl = Uri.parse('https://pub.dev/packages/chat_toolkit');
final _githubUrl = Uri.parse('https://github.com/ws5260/chat_toolkit');

enum SitePage {
  playground('플레이그라운드', Icons.tune_rounded),
  examples('예제', Icons.forum_outlined),
  gettingStarted('시작하기', Icons.menu_book_outlined);

  const SitePage(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The demo web site: a header with the menu, and the selected page below it.
class SiteShell extends StatefulWidget {
  const SiteShell({super.key, required this.demoScreenBuilder});

  /// The single-room demo listed on the examples page.
  final WidgetBuilder demoScreenBuilder;

  @override
  State<SiteShell> createState() => _SiteShellState();
}

class _SiteShellState extends State<SiteShell> {
  SitePage _page = SitePage.playground;

  void _go(SitePage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 820;
    return Scaffold(
      body: Column(children: [
        _Header(current: _page, compact: compact, onSelect: _go),
        Expanded(
          // Pages stay alive so the playground keeps its chat when switching menus.
          child: IndexedStack(index: _page.index, children: [
            const PlaygroundPage(),
            ExamplesPage(demoScreenBuilder: widget.demoScreenBuilder),
            GettingStartedPage(onOpenPlayground: () => _go(SitePage.playground)),
          ]),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.current, required this.compact, required this.onSelect});

  final SitePage current;
  final bool compact;
  final ValueChanged<SitePage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: SiteColors.grey200)),
      ),
      child: Row(children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelect(SitePage.playground),
          child: const _Logo(),
        ),
        if (!compact) ...[
          const SizedBox(width: 32),
          for (final page in SitePage.values)
            _NavItem(
              label: page.label,
              selected: page == current,
              onTap: () => onSelect(page),
            ),
          const Spacer(),
          const _VersionPill(),
          const SizedBox(width: 12),
          _LinkButton(label: 'pub.dev', url: _pubUrl),
          _LinkButton(label: 'GitHub', url: _githubUrl),
        ] else ...[
          const Spacer(),
          IconButton(
            tooltip: '메뉴',
            icon: const Icon(Icons.menu_rounded, color: SiteColors.grey800),
            onPressed: () => _openMenu(context),
          ),
        ],
      ]),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final page in SitePage.values)
              _MenuRow(
                icon: page.icon,
                label: page.label,
                selected: page == current,
                onTap: () {
                  Navigator.pop(sheetContext);
                  onSelect(page);
                },
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Divider(),
            ),
            _MenuRow(
              icon: Icons.inventory_2_outlined,
              label: 'pub.dev',
              trailing: Icons.open_in_new_rounded,
              onTap: () => launchUrl(_pubUrl),
            ),
            _MenuRow(
              icon: Icons.code_rounded,
              label: 'GitHub',
              trailing: Icons.open_in_new_rounded,
              onTap: () => launchUrl(_githubUrl),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: SiteColors.blue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('chat_toolkit',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: SiteColors.grey900)),
        ]),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? SiteColors.grey100 : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? SiteColors.grey900 : SiteColors.grey600,
                )),
          ),
        ),
      );
}

class _VersionPill extends StatelessWidget {
  const _VersionPill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: SiteColors.blueWeak,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text('v$_version',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: SiteColors.blue)),
      );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.url});

  final String label;
  final Uri url;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => launchUrl(url),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.north_east_rounded, size: 14),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: SiteColors.grey700,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? SiteColors.blueWeak : SiteColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 20, color: selected ? SiteColors.blue : SiteColors.grey700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: SiteColors.grey900,
                  )),
            ),
            if (trailing != null) Icon(trailing, size: 18, color: SiteColors.grey400),
          ]),
        ),
      );
}
