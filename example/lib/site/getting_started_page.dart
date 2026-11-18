import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'site_theme.dart';

/// Short setup guide: install, then four steps.
class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key, required this.onOpenPlayground});

  final VoidCallback onOpenPlayground;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 64),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.navGettingStarted, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                l.gsIntro,
                style: const TextStyle(fontSize: 15, color: SiteColors.grey600, height: 1.6),
              ),
              const SizedBox(height: 24),
              _Step(
                number: 1,
                title: l.step1Title,
                code: 'flutter pub add chat_toolkit',
              ),
              _Step(
                number: 2,
                title: l.step2Title,
                description: l.step2Desc,
                code: '''class TextElement extends MessageElement {
  const TextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) => Text(text);

  @override
  TextElement copyWith() => TextElement(text);
}''',
              ),
              _Step(
                number: 3,
                title: l.step3Title,
                description: l.step3Desc,
                code: '''final chatController = ChatController();

Chat(
  chatController: chatController,
  onScrollToTop: () async {
    final older = await api.fetchOlder();
    chatController.appendMessages(older);
  },
  configuration: const ChatConfiguration(
    messagesStartAtTop: true,
    messageAppearAnimationDuration: Duration(milliseconds: 250),
  ),
)''',
              ),
              _Step(
                number: 4,
                title: l.step4Title,
                description: l.step4Desc,
                code: '''chatController.dispatchMessage(
  SenderMessage(
    name: 'Me',
    timestamp: DateTime.now().toIso8601String(),
    elements: [TextElement(text)],
  ),
  onDispatch: (message) async {
    final ok = await api.send(message);
    return ok ? message.copyWith(isLoading: false) : null;
  },
);''',
              ),
              const SizedBox(height: 8),
              SiteCard(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.gsCtaTitle,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(l.gsCtaDesc,
                          style: const TextStyle(fontSize: 14, color: SiteColors.grey600)),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  SiteButton(label: l.gsCtaButton, primary: true, onPressed: onOpenPlayground),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, this.description, required this.code});

  final int number;
  final String title;
  final String? description;
  final String code;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SiteCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: SiteColors.blue, shape: BoxShape.circle),
                child: Text('$number',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ]),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!,
                  style: const TextStyle(fontSize: 14, color: SiteColors.grey600, height: 1.5)),
            ],
            const SizedBox(height: 14),
            Stack(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 48, 14),
                decoration: BoxDecoration(
                  color: SiteColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SiteColors.grey200),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(code,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.6,
                          color: SiteColors.grey800)),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  tooltip: AppLocalizations.of(context).copy,
                  iconSize: 16,
                  color: SiteColors.grey500,
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).copied)));
                  },
                ),
              ),
            ]),
          ]),
        ),
      );
}
