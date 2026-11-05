# Chat Toolkit

A customizable chat widget toolkit for Flutter. It gives you a ready-to-use chat UI with message grouping, async sending with retry, and an optimized scrolling list.

## Contents

- [Features](#features)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Customization](#customization)
- [API reference](#api-reference)
- [Requirements](#requirements)

## Features

| Area | What you get |
| --- | --- |
| **UI** | Chat widget with message list, input field, profiles, timestamps, read-only mode |
| **Messages** | Sender/receiver messages, extensible message elements, loading / failed / success states |
| **Sending** | Async dispatch with result stream, retry for failed messages, blocked-message handling |
| **Grouping & sorting** | Automatic message grouping (customizable), tie-breaker sorting for identical timestamps |
| **Scrolling** | New-message notification, load older messages, only visible groups are built |

## Installation

```yaml
dependencies:
  chat_toolkit: ^latest_version
```

```bash
flutter pub get
```

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:chat_toolkit/chat_toolkit.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final chatController = ChatController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Chat(
        chatController: chatController,
        configuration: ChatConfiguration(),
      ),
    );
  }

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }
}
```

## Usage

### Add a message

```dart
chatController.addMessage(
  SenderMessage(
    name: 'You',
    timestamp: DateTime.now().toIso8601String(),
    elements: [TextMessageElement(text: 'Hello!')],
  ),
);
```

### Message types

```dart
// Outgoing
SenderMessage(
  name: 'User Name',
  timestamp: DateTime.now().toIso8601String(),
  elements: [TextMessageElement(text: 'Hello world!')],
);

// Incoming
ReceiverMessage(
  id: 'unique_id',
  name: 'Other User',
  timestamp: DateTime.now().toIso8601String(),
  elements: [TextMessageElement(text: 'Hi there!')],
);
```

### Send asynchronously

```dart
final result = await chatController.dispatchMessage(
  message,
  onDispatch: (message) async {
    final response = await yourApiCall(message);
    return response; // processed message, or null if it failed
  },
);
```

While sending, the bubble shows a loading state. On failure it shows retry / delete buttons.

### Handle blocked messages and failed bubbles

```dart
// Throw from onDispatch when the server blocks the message.
// The bubble is removed and no retry entry is created.
onDispatch: (message) async {
  final response = await yourApiCall(message);
  if (response.isBlocked) {
    throw MessageBlockedException(code: response.code, message: response.text);
  }
  return response.message;
},
```

```dart
// Delete button on a failed bubble.
// The message is removed only if this returns true.
Chat(
  chatController: chatController,
  onDeleteFailedMessage: (message) async => await yourDeleteApi(message),
)
```

```dart
// Make a failed message loaded from history retryable.
chatController.registerFailedMessage(messageId, onDispatch);
```

### Load older messages

```dart
Chat(
  chatController: chatController,
  onScrollToTop: () async {
    final olderMessages = await fetchOlderMessages();
    chatController.appendMessages(olderMessages);
  },
)
```

### Listen to events

```dart
chatController.dispatchResultStream.listen((result) {
  if (result.isSuccess) {
    print('Message sent');
  } else {
    print('Failed: ${result.exception}');
  }
});

chatController.newReceiveMessageStream.listen((message) {
  print('New message: ${message.id}');
});
```

## Customization

### Appearance

```dart
Chat(
  chatController: chatController,
  configuration: ChatConfiguration(
    senderAlignment: ChatAlignment.end,
    bubbleConfiguration: BubbleConfiguration(
      maxWidth: 280,
      profileBuilder: (context, name) => CustomProfile(name),
      senderBubbleBuilder: (context, child) => CustomBubble(child),
    ),
  ),
)
```

### Custom message elements

```dart
class ImageElement extends MessageElement {
  final String url;
  const ImageElement({required this.url});

  @override
  Widget toWidget(BuildContext context) => Image.network(url);

  @override
  MessageElement copyWith() => ImageElement(url: url);
}
```

### Sorting messages with identical timestamps

```dart
final controller = ChatController(
  customSortCallback: (a, b) => a.id.compareTo(b.id),
);
```

### Message grouping

By default, consecutive messages are grouped when they have the same sender, the same name, and the same minute. Add your own condition on top of that:

```dart
final controller = ChatController(
  additionalGroupCondition: (group, message) {
    return group.messages.length < 10; // e.g. at most 10 messages per group
  },
);
```

## API reference

### ChatConfiguration

| Option | Description |
| --- | --- |
| `senderAlignment` | Message alignment (start / end) |
| `padding` | List padding (default: horizontal 30) |
| `customInputField` | Custom input field widget |
| `newReceiveMessageNotificationBuilder` | Builder for the new-message notification |
| `bubbleConfiguration` | Bubble appearance settings |
| `readOnlyWidget` | Widget shown in read-only mode |

### BubbleConfiguration

| Option | Description |
| --- | --- |
| `profileBuilder` | Profile widget builder |
| `senderBubbleBuilder` | Sender bubble builder |
| `receiverBubbleBuilder` | Receiver bubble builder |
| `timeBuilder` | Timestamp builder |
| `loadingWidget` | Loading indicator |
| `maxWidth` | Maximum bubble width |

### ChatController

| Option | Description |
| --- | --- |
| `customSortCallback` | Tie-breaker for messages with identical timestamps |
| `additionalGroupCondition` | Extra condition for joining a message group |

## Requirements

- Flutter SDK >= 3.24.0
- Dart SDK ^3.12.0

Dependencies: `gap`, `intl`, `super_sliver_list`, `uuid`.

## Contributing

Contributions are welcome. Feel free to open a pull request.

## License

MIT License. See [LICENSE](LICENSE).

## Support

For issues, feature requests, or questions, visit the [GitHub repository](https://github.com/ws5260/chat_toolkit).
