import 'package:flutter/material.dart';
import 'package:chat_toolkit/chat_toolkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Toolkit Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

// 간단한 텍스트 메시지 요소 구현
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
  late final ChatController chatController;
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    chatController = ChatController();

    // 초기 메시지들 추가
    _loadInitialMessages();
  }

  void _loadInitialMessages() {
    final now = DateTime.now();

    // 받은 메시지
    final receivedMessage = ReceiverMessage(
      id: 'msg1',
      timestamp: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      name: '상담사',
      elements: [
        const TextMessageElement('안녕하세요! 무엇을 도와드릴까요?'),
      ],
    );

    // 보낸 메시지
    final sentMessage = SenderMessage(
      timestamp: now.subtract(const Duration(minutes: 3)).toIso8601String(),
      name: '나',
      elements: [
        const TextMessageElement('안녕하세요! 채팅 기능 테스트 중입니다.'),
      ],
    );

    // 또 다른 받은 메시지
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

    // 하단으로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatController.scrollToBottom();
    });
  }

  void _sendMessage() {
    if (textController.text.trim().isEmpty) return;

    final message = SenderMessage(
      timestamp: DateTime.now().toIso8601String(),
      name: '나',
      elements: [
        TextMessageElement(textController.text.trim()),
      ],
    );

    // 메시지 전송 시뮬레이션
    chatController.dispatchMessage(
      message,
      onDispatch: (message) async {
        // 실제 API 호출을 시뮬레이션
        await Future.delayed(const Duration(seconds: 1));

        // 자동 응답 생성
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

        // 자동 응답 추가
        WidgetsBinding.instance.addPostFrameCallback((_) {
          chatController.addMessage(response);
          chatController.scrollToBottom();
        });

        return message.copyWith(isLoading: false);
      },
    );

    textController.clear();
  }

  @override
  void dispose() {
    textController.dispose();
    chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Chat Toolkit Demo'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Chat(
              chatController: chatController,
              configuration: ChatConfiguration(
                bubbleConfiguration: BubbleConfiguration(
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
                  profileBuilder: (context, name) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        name[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  },
                ),
                customInputField: (context, controller) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: '메시지를 입력하세요...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
