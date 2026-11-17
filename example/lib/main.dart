import 'package:chat_toolkit/chat_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'rooms/fake_chat_server.dart';
import 'rooms/room_list_screen.dart';
import 'site/site_locale.dart';
import 'site/site_shell.dart';
import 'site/site_theme.dart';

void main() {
  runApp(const MyApp());
}

/// First screen of the example app.
enum AppHome { site, rooms }

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home = AppHome.site});

  /// [AppHome.site] is the demo web site (playground, examples, guide); [AppHome.rooms] opens
  /// the plain example list.
  final AppHome home;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: siteLocale,
      builder: (context, locale, _) {
        // The fake server writes its messages in the site language.
        FakeChatServer.instance.language = locale.languageCode;
        return MaterialApp(
          title: 'chat_toolkit',
          debugShowCheckedModeBanner: false,
          theme: buildSiteTheme(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: switch (home) {
            AppHome.site => const SiteShell(),
            AppHome.rooms => RoomListScreen(demoScreenBuilder: (_) => const ChatScreen()),
          },
        );
      },
    );
  }
}

// Minimal text message element implementation
class TextMessageElement extends MessageElement {
  final String text;
  final TextStyle? style;

  const TextMessageElement(this.text, {this.style});

  @override
  Widget toWidget(BuildContext context) {
    return Text(
      text,
      style: style ??
          const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
    );
  }

  @override
  MessageElement copyWith({String? text, TextStyle? style}) {
    return TextMessageElement(
      text ?? this.text,
      style: style ?? this.style,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController chatController;

  final TextEditingController textController = TextEditingController();
  // Kept on the input after sending (see _sendMessage and _buildInputField).
  final FocusNode inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    chatController = ChatController();

    // Seed initial messages
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    final now = DateTime.now();

    // Received message
    final receivedMessage = ReceiverMessage(
      id: 'msg1',
      timestamp: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      name: '상담사',
      elements: [
        const TextMessageElement('안녕하세요! 무엇을 도와드릴까요?'),
      ],
    );

    // Sent message
    final sentMessage = SenderMessage(
      timestamp: now.subtract(const Duration(minutes: 3)).toIso8601String(),
      name: '나',
      elements: [
        const TextMessageElement('안녕하세요! 채팅 기능 테스트 중입니다.'),
      ],
    );

    // Another received message
    final receivedMessage2 = ReceiverMessage(
      id: 'msg3',
      timestamp: now.subtract(const Duration(minutes: 1)).toIso8601String(),
      name: '상담사',
      elements: [
        const TextMessageElement('네, 잘 작동하고 있는 것 같네요! 다른 질문이 있으시면 언제든 말씀해주세요.'),
      ],
    );

    chatController
        .setMessages([receivedMessage, sentMessage, receivedMessage2]);

    // Scroll to the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatController.scrollToBottom();
    });
  }

  // Received messages go through dispatchMessage so that the chat's
  // newReceiveMessageStream fires: within newMessageScrollThreshold of the
  // bottom it scrolls down, otherwise newReceiveMessageNotificationBuilder
  // shows a "new message" notification. addMessage does not fire it.
  void _receiveMessage(Message message) {
    chatController.dispatchMessage(
      message,
      onDispatch: (message) async => message,
    );
  }

  int _simulatedCount = 0;

  // Simulates a message pushed by the server (e.g. over a socket).
  void _simulateIncomingMessage() {
    _simulatedCount++;
    _receiveMessage(ReceiverMessage(
      id: 'incoming_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String(),
      name: '상담사',
      elements: [TextMessageElement('수신 테스트 메시지 $_simulatedCount')],
    ));
  }

  void _sendMessage() {
    // Clicking the send button moves focus to it on web/desktop; give it back to the input.
    inputFocusNode.requestFocus();
    if (textController.text.trim().isEmpty) return;

    final message = SenderMessage(
      timestamp: DateTime.now().toIso8601String(),
      name: '나',
      elements: [
        TextMessageElement(textController.text.trim()),
      ],
    );

    // Simulate sending a message
    chatController.dispatchMessage(
      message,
      onDispatch: (message) async {
        // Simulate a real API call
        await Future.delayed(const Duration(seconds: 1));

        // Generate an auto reply
        final responses = [
          '메시지를 잘 받았습니다!',
          '네, 이해했습니다.',
          '더 도움이 필요하시면 말씀해주세요.',
          '좋은 질문이네요!',
          '알겠습니다. 확인해보겠습니다.',
        ];

        final response = ReceiverMessage(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now().toIso8601String(),
          name: '상담사',
          elements: [
            TextMessageElement(
                responses[DateTime.now().millisecond % responses.length]),
          ],
        );

        // Deliver the auto reply as a received message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _receiveMessage(response);
        });

        return message.copyWith(isLoading: false);
      },
    );

    textController.clear();
  }

  @override
  void dispose() {
    textController.dispose();
    inputFocusNode.dispose();
    chatController.dispose();
    super.dispose();
  }

  // Collects the text of a message so the menu can copy it.
  String _plainText(Message message) => message.elements
      .whereType<TextMessageElement>()
      .map((element) => element.text)
      .join('\n');

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // A long press on a bubble opens these menus.
  // Sender and receiver get a different set of entries.
  //
  // Styled to read like a web dropdown rather than a mobile sheet: thin border,
  // small radius, low elevation, compact 32px rows, 13px text, and no open
  // animation. All of it is plain BubbleMenuConfiguration / BubbleMenuItem
  // options — no custom menu code.
  static const _menuTextColor = Color(0xFF202124);
  static const _menuIconColor = Color(0xFF5F6368);
  static const _menuDangerColor = Color(0xFFD93025);

  // One compact, web-looking row.
  BubbleMenuItem _menuItem({
    required String label,
    required IconData icon,
    BubbleMenuItemCallback? onSelected,
    bool enabled = true,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? _menuDangerColor : _menuTextColor;
    return BubbleMenuItem(
      label: label,
      icon: Icon(
        icon,
        size: 16,
        color: isDestructive ? _menuDangerColor : _menuIconColor,
      ),
      enabled: enabled,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: TextStyle(fontSize: 13, color: color),
      onSelected: onSelected,
    );
  }

  void _copy(BuildContext context, BubbleMenuRequest request) {
    Clipboard.setData(ClipboardData(text: _plainText(request.message)));
    _showSnackBar(context, '복사했습니다');
  }

  BubbleMenuConfiguration get _bubbleMenu => BubbleMenuConfiguration(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Color(0xFFE2E2E2)),
        ),
        constraints: const BoxConstraints(minWidth: 176),
        // Web dropdowns appear instantly instead of expanding.
        animationStyle: AnimationStyle.noAnimation,
        senderItemsBuilder: (context, request) {
          // No menu while the message is still being sent.
          if (request.message.isLoading) return const [];
          return [
            _menuItem(label: '복사', icon: Icons.copy, onSelected: _copy),
            _menuItem(
              label: '재전송',
              icon: Icons.refresh,
              enabled: request.message.isFailed,
              onSelected: (context, request) =>
                  chatController.retryMessage(request.message),
            ),
            _menuItem(
              label: '삭제',
              icon: Icons.delete_outline,
              isDestructive: true,
              onSelected: (context, request) =>
                  chatController.removeMessageEverywhere(request.message),
            ),
          ];
        },
        receiverItemsBuilder: (context, request) {
          if (request.message.isLoading) return const [];
          return [
            _menuItem(label: '복사', icon: Icons.copy, onSelected: _copy),
            _menuItem(
              label: '답장',
              icon: Icons.reply,
              onSelected: (context, request) => _showSnackBar(
                context,
                '${request.message.name}님에게 답장',
              ),
            ),
            _menuItem(
              label: '신고',
              icon: Icons.flag_outlined,
              onSelected: (context, request) =>
                  _showSnackBar(context, '신고했습니다'),
            ),
          ];
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Chat Toolkit Demo'),
        actions: [
          IconButton(
            tooltip: '메시지 수신 테스트',
            icon: const Icon(Icons.mark_chat_unread_outlined),
            onPressed: _simulateIncomingMessage,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '말풍선을 길게 누르면(터치·마우스 모두 꾹 누르기) 메뉴가 열립니다. '
              '오른쪽 위 버튼으로 메시지 수신을 테스트할 수 있습니다. '
              '보낸 메시지와 받은 메시지의 메뉴가 서로 다릅니다.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Chat(
              // A new key rebuilds Chat for the new controller.
              key: ValueKey(chatController),
              chatController: chatController,
              configuration: ChatConfiguration(
                // A few messages start at the top instead of the bottom.
                messagesStartAtTop: true,
                // New messages grow in from the bottom instead of popping in.
                messageAppearAnimationDuration:
                    const Duration(milliseconds: 250),
                // Enables auto-scroll on received messages near the bottom and
                // shows this notification when scrolled further up.
                newReceiveMessageNotificationBuilder:
                    (context, message, controller) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ActionChip(
                      avatar: const Icon(Icons.arrow_downward, size: 16),
                      label: Text('새 메시지: ${message.name}'),
                      onPressed: controller.scrollToBottom,
                    ),
                  );
                },
                bubbleConfiguration: BubbleConfiguration(
                  menuConfiguration: _bubbleMenu,
                  senderBubbleBuilder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        child: child,
                      ),
                    );
                  },
                  receiverBubbleBuilder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                        child: child,
                      ),
                    );
                  },
                  timeBuilder: (context, timestamp) {
                    final time = DateTime.parse(timestamp);
                    return Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              customInputField: (context, controller) => _buildInputField(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: inputFocusNode,
                textInputAction: TextInputAction.send,
                // With onEditingComplete set, pressing Enter no longer unfocuses the field
                // (TextField unfocuses on submit only when it is null).
                onEditingComplete: _sendMessage,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
