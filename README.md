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
| **Context menu** | Long press menu on bubbles, configured separately for sender and receiver |
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

### Bubble context menu

Long pressing a bubble opens a context menu — a held touch, or a held mouse button on desktop and web. Sender and receiver menus are configured separately, so each side can offer different entries.

```dart
Chat(
  chatController: chatController,
  configuration: ChatConfiguration(
    bubbleConfiguration: BubbleConfiguration(
      menuConfiguration: BubbleMenuConfiguration(
        senderItemsBuilder: (context, request) => [
          BubbleMenuItem(
            label: 'Copy',
            icon: const Icon(Icons.copy, size: 18),
            onSelected: (context, request) => copy(request.message),
          ),
          BubbleMenuItem(
            label: 'Resend',
            enabled: request.message.isFailed,
            onSelected: (context, request) =>
                chatController.retryMessage(request.message),
          ),
          BubbleMenuItem(
            label: 'Delete',
            textStyle: const TextStyle(color: Colors.red),
            onSelected: (context, request) =>
                chatController.removeMessageEverywhere(request.message),
          ),
        ],
        receiverItemsBuilder: (context, request) => [
          BubbleMenuItem(label: 'Reply', onSelected: reply),
          BubbleMenuItem(label: 'Report', onSelected: report),
        ],
      ),
    ),
  ),
)
```

A side without an items builder has no menu, and returning an empty list suppresses the menu for that message (useful while it is still sending).

`request` is a `BubbleMenuRequest` carrying the `message`, `isSender`, the pointer's `globalPosition`, and the bubble's `bubbleRect` in global coordinates.

#### Animation

The default menu uses Material's popup transition (fade + vertical expand). `animationStyle` retimes it:

```dart
BubbleMenuConfiguration(
  animationStyle: const AnimationStyle(
    duration: Duration(milliseconds: 150),
    curve: Curves.easeOutCubic,
    reverseDuration: Duration(milliseconds: 100),
  ),
  // or AnimationStyle.noAnimation to show it instantly
)
```

For a different *kind* of transition (scale out of the bubble, blurred backdrop, spring), present your own menu with a handler — see below. `request.bubbleRect` and `request.globalPosition` give you the anchor.

#### Custom menu UI

For a bottom sheet, dialog, or your own overlay, use a handler instead of items. It replaces the default popup menu for that side.

```dart
BubbleMenuConfiguration(
  receiverMenuHandler: (context, request) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => MyMenuSheet(message: request.message),
    );
  },
)
```

#### Options

| Option | Description |
| --- | --- |
| `senderItemsBuilder` / `receiverItemsBuilder` | Entries of the default menu, per side |
| `senderMenuHandler` / `receiverMenuHandler` | Custom menu presentation, per side (takes precedence over items) |
| `enableLongPress` | Open on long press (default: `true`) |
| `enableHapticFeedback` | Vibrate when the menu opens (default: `true`) |
| `color`, `surfaceTintColor`, `shape`, `elevation`, `constraints` | Styling of the default popup menu |
| `animationStyle` | Duration / curve of the default menu's transition (`AnimationStyle.noAnimation` to disable) |

> Right click is deliberately not a trigger: on Flutter web it would open the browser's own context menu at the same time. A held mouse button works as a long press, so desktop and web users still get the menu.

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
| `menuConfiguration` | Long press context menu, per side |

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
