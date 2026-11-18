import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../playground/playground_screen.dart';
import 'examples_page.dart';
import 'getting_started_page.dart';
import 'site_locale.dart';
import 'site_theme.dart';

const _version = '2.0.0';
final _pubUrl = Uri.parse('https://pub.dev/packages/chat_toolkit');
final _githubUrl = Uri.parse('https://github.com/ws5260/chat_toolkit');

enum SitePage {
  playground(Icons.tune_rounded),
  examples(Icons.forum_outlined),
  gettingStarted(Icons.menu_book_outlined);

  const SitePage(this.icon);
  final IconData icon;

  String label(AppLocalizations l) => switch (this) {
        SitePage.playground => l.navPlayground,
        SitePage.examples => l.navExamples,
        SitePage.gettingStarted => l.navGettingStarted,
      };
}

/// The demo web site: a header with the menu, and the selected page below it.
class SiteShell extends StatefulWidget {
  const SiteShell({super.key});

  @override
  State<SiteShell> createState() => _SiteShellState();
}

class _SiteShellState extends State<SiteShell> {
  SitePage _page = SitePage.playground;

  void _go(SitePage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 960;
    return Scaffold(
      body: Column(children: [
        _Header(current: _page, compact: compact, onSelect: _go),
        Expanded(
          // Pages stay alive so the playground keeps its chat when switching menus.
          child: IndexedStack(index: _page.index, children: [
            const PlaygroundPage(),
            const ExamplesPage(),
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
    final l = AppLocalizations.of(context);
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
          // Scrolls instead of overflowing when the window is just wide enough.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final page in SitePage.values)
                  _NavItem(
                    label: page.label(l),
                    selected: page == current,
                    onTap: () => onSelect(page),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          const _VersionPill(),
          const SizedBox(width: 8),
          const _LanguageSwitch(),
          const SizedBox(width: 4),
          _LinkButton(label: 'pub.dev', url: _pubUrl),
          _LinkButton(label: 'GitHub', url: _githubUrl),
        ] else ...[
          const Spacer(),
          IconButton(
            tooltip: l.menu,
            icon: const Icon(Icons.menu_rounded, color: SiteColors.grey800),
            onPressed: () => _openMenu(context, l),
          ),
        ],
      ]),
    );
  }

  void _openMenu(BuildContext context, AppLocalizations l) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final page in SitePage.values)
              _MenuRow(
                icon: page.icon,
                label: page.label(l),
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
            for (final entry in siteLanguageNames.entries)
              _MenuRow(
                icon: Icons.translate_rounded,
                label: entry.value,
                selected: siteLocale.value.languageCode == entry.key,
                onTap: () {
                  Navigator.pop(sheetContext);
                  siteLocale.value = Locale(entry.key);
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
          Image.asset('assets/logo.png', width: 34, height: 34, filterQuality: FilterQuality.medium),
          const SizedBox(width: 8),
          const Text('Chat Toolkit',
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

/// Picks the site language.
class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch();

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    return PopupMenuButton<String>(
      tooltip: 'Language',
      position: PopupMenuPosition.under,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (code) => siteLocale.value = Locale(code),
      itemBuilder: (_) => [
        for (final entry in siteLanguageNames.entries)
          PopupMenuItem(
            value: entry.key,
            child: Row(children: [
              Expanded(child: Text(entry.value)),
              if (entry.key == current)
                const Icon(Icons.check_rounded, size: 18, color: SiteColors.blue),
            ]),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.translate_rounded, size: 18, color: SiteColors.grey700),
          const SizedBox(width: 6),
          Text(siteLanguageNames[current] ?? current,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: SiteColors.grey700)),
          const Icon(Icons.expand_more_rounded, size: 18, color: SiteColors.grey500),
        ]),
      ),
    );
  }
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
