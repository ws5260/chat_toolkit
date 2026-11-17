import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'site_theme.dart';

/// Short setup guide: install, then four steps.
class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key, required this.onOpenPlayground});

  final VoidCallback onOpenPlayground;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 64),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('시작하기', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                '메시지 묶기, 날짜 구분선, 전송 실패와 재전송, 이전 메시지 불러오기를 '
                'ChatController 하나로 다룰 수 있어요.',
                style: TextStyle(fontSize: 15, color: SiteColors.grey600, height: 1.6),
              ),
              const SizedBox(height: 24),
              const _Step(
                number: 1,
                title: '패키지를 설치해요',
                code: 'flutter pub add chat_toolkit',
              ),
              const _Step(
                number: 2,
                title: '메시지 내용을 그릴 요소를 만들어요',
                description: '텍스트, 이미지 등 말풍선 안에 들어갈 내용을 MessageElement 로 정의해요.',
                code: '''class TextElement extends MessageElement {
  const TextElement(this.text);
  final String text;

  @override
  Widget toWidget(BuildContext context) => Text(text);

  @override
  TextElement copyWith() => TextElement(text);
}''',
              ),
              const _Step(
                number: 3,
                title: '채팅 화면을 붙여요',
                description: '서버에서 받은 메시지는 setMessages, 위로 스크롤해서 받은 이전 메시지는 appendMessages 로 넣어요.',
                code: '''final chatController = ChatController(reverse: true);

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
              const _Step(
                number: 4,
                title: '메시지를 보내요',
                description: 'null 을 돌려주면 실패로 표시되고, 길게 눌러 다시 보낼 수 있어요.',
                code: '''chatController.dispatchMessage(
  SenderMessage(
    name: '나',
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
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('옵션을 직접 바꿔 보고 싶다면',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('플레이그라운드에서 설정마다 어떻게 달라지는지 바로 볼 수 있어요.',
                          style: TextStyle(fontSize: 14, color: SiteColors.grey600)),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  SiteButton(label: '열어 보기', primary: true, onPressed: onOpenPlayground),
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
                  tooltip: '복사',
                  iconSize: 16,
                  color: SiteColors.grey500,
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('복사했어요')));
                  },
                ),
              ),
            ]),
          ]),
        ),
      );
}
