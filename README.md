# Chat Toolkit

A comprehensive and customizable chat widget toolkit for Flutter applications. This package provides a complete chat interface with message handling, real-time updates, and extensive customization options.

## Features

- **Complete Chat Interface**: Ready-to-use chat widget with message display and input functionality
- **Message Management**: Support for different message types (sender/receiver) with state management
- **Real-time Updates**: Stream-based message handling for live chat experiences
- **Customizable UI**: Fully customizable message bubbles, profiles, and input fields
- **Message States**: Built-in support for loading, failed, and success message states
- **Message Grouping**: Automatic message organization and grouping
- **Custom Message Sorting**: Configurable priority system for messages with identical timestamps
- **Responsive Design**: Auto-sizing components that adapt to different screen sizes
- **Read-only Mode**: Display-only chat interfaces for viewing conversations
- **Scroll Management**: Intelligent scroll behavior with new message notifications

## Getting Started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  chat_toolkit: $latest_version
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:chat_toolkit/chat_toolkit.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController chatController;

  @override
  void initState() {
    super.initState();
    chatController = ChatController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
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

## Core Usage

### Adding Messages

```dart
// Add a simple text message
chatController.addMessage(
  SenderMessage(
    name: 'You',
    timestamp: DateTime.now().toIso8601String(),
    elements: [TextMessageElement(text: 'Hello!')],
  ),
);
```

### Async Message Sending

```dart
final result = await chatController.dispatchMessage(
  message,
  onDispatch: (message) async {
    // Your API call here
    final response = await yourApiCall(message);
    return response; // Return processed message or null if failed
  },
);
```

### Loading More Messages

```dart
Chat(
  chatController: chatController,
  onScrollToTop: () async {
    final olderMessages = await fetchOlderMessages();
    chatController.appendMessages(olderMessages);
  },
)
```

## Customization

### Basic Configuration

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

### Custom Message Elements

```dart
class ImageElement extends MessageElement {
  final String url;
  const ImageElement({required this.url});

  @override
  Widget toWidget(BuildContext context) {
    return Image.network(url);
  }

  @override
  MessageElement copyWith() => ImageElement(url: url);
}
```

### Custom Message Sorting

```dart
final controller = ChatController(
  customSortCallback: (message1, message2) {
    // Custom sorting for messages with identical timestamps
    return message1.id.compareTo(message2.id);
  },
);
```

## Configuration Options

### ChatConfiguration

- `senderAlignment`: Message alignment (start/end)
- `customInputField`: Custom input field widget
- `newReceiveMessageNotificationBuilder`: New message notification builder
- `bubbleConfiguration`: Bubble appearance settings
- `readOnlyWidget`: Widget for read-only mode

### BubbleConfiguration

- `profileBuilder`: Custom profile widget builder
- `senderBubbleBuilder`: Custom sender bubble builder
- `receiverBubbleBuilder`: Custom receiver bubble builder
- `timeBuilder`: Custom timestamp builder
- `loadingWidget`: Custom loading indicator
- `maxWidth`: Maximum bubble width

## Message Types

```dart
// Sender message (outgoing)
SenderMessage(
  name: 'User Name',
  timestamp: DateTime.now().toIso8601String(),
  elements: [TextMessageElement(text: 'Hello world!')],
);

// Receiver message (incoming)
ReceiverMessage(
  id: 'unique_id',
  name: 'Other User',
  timestamp: DateTime.now().toIso8601String(),
  elements: [TextMessageElement(text: 'Hi there!')],
);
```

## Event Streams

```dart
// Listen to dispatch results
chatController.dispatchResultStream.listen((result) {
  if (result.isSuccess) {
    print('Message sent successfully');
  } else {
    print('Failed: ${result.exception}');
  }
});

// Listen to new received messages
chatController.newReceiveMessageStream.listen((message) {
  print('New message: ${message.id}');
});
```

## Requirements

- Flutter SDK: >=3.24.0
- Dart SDK: ^3.5.0

## Dependencies

- `gap`: ^3.0.1 - For spacing utilities
- `intl`: ^0.19.0 - For internationalization
- `uuid`: ^4.5.1 - For unique ID generation

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, feature requests, or questions, please visit our [GitHub repository](https://github.com/ws5260/chat_toolkit).
