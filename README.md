# Chat Toolkit

A comprehensive and customizable chat widget toolkit for Flutter applications. This package provides a complete chat interface with message handling, real-time updates, and extensive customization options.

## Features

- **Complete Chat Interface**: Ready-to-use chat widget with message display and input functionality
- **Message Management**: Support for different message types (sender/receiver) with state management
- **Real-time Updates**: Stream-based message handling for live chat experiences
- **Customizable UI**: Fully customizable message bubbles, profiles, and input fields
- **Message States**: Built-in support for loading, failed, and success message states
- **Message Grouping**: Automatic message organization and grouping
- **Responsive Design**: Auto-sizing components that adapt to different screen sizes
- **Read-only Mode**: Display-only chat interfaces for viewing conversations
- **Scroll Management**: Intelligent scroll behavior with new message notifications
- **Internationalization**: Built-in i18n support

## Getting Started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  chat_toolkit: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Implementation

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

    // Add some sample messages
    chatController.setMessages([
      ReceiverMessage(
        id: '1',
        name: 'John',
        timestamp: DateTime.now().toIso8601String(),
        elements: [TextMessageElement(text: 'Hello! How are you?')],
      ),
      SenderMessage(
        name: 'You',
        timestamp: DateTime.now().toIso8601String(),
        elements: [TextMessageElement(text: 'I\'m doing great, thanks!')],
      ),
    ]);
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

### Custom Configuration

```dart
Chat(
  chatController: chatController,
  configuration: ChatConfiguration(
    senderAlignment: ChatAlignment.end,
    bubbleConfiguration: BubbleConfiguration(
      maxWidth: 280,
      profileBuilder: (context, name) => CustomProfileWidget(name),
      senderBubbleBuilder: (context, child) => CustomBubble(
        child: child,
        color: Colors.blue,
      ),
      receiverBubbleBuilder: (context, child) => CustomBubble(
        child: child,
        color: Colors.grey[200],
      ),
    ),
    customInputField: (context, controller) => CustomInputField(
      controller: controller,
    ),
  ),
)
```

### Message Handling

```dart
// Adding new messages
chatController.addMessage(
  SenderMessage(
    name: 'You',
    timestamp: DateTime.now().toIso8601String(),
    elements: [TextMessageElement(text: 'New message')],
  ),
);

// Listening to message dispatch results
chatController.dispatchResultStream.listen((result) {
  if (result.isSuccess) {
    print('Message sent successfully');
  } else {
    print('Failed to send message: ${result.exception}');
  }
});

// Listening to new received messages
chatController.newReceiveMessageStream.listen((message) {
  print('New message received: ${message.id}');
});
```

### Read-only Mode

```dart
Chat(
  readOnly: true,
  chatController: chatController,
  configuration: ChatConfiguration(),
)
```

## Message Types

### Creating Messages

```dart
// Sender message
final senderMessage = SenderMessage(
  name: 'User Name',
  timestamp: DateTime.now().toIso8601String(),
  elements: [TextMessageElement(text: 'Hello world!')],
);

// Receiver message
final receiverMessage = ReceiverMessage(
  id: 'unique_id',
  name: 'Other User',
  timestamp: DateTime.now().toIso8601String(),
  elements: [TextMessageElement(text: 'Hi there!')],
);

// Message with loading state
final loadingMessage = SenderMessage(
  name: 'User Name',
  timestamp: DateTime.now().toIso8601String(),
  elements: [TextMessageElement(text: 'Sending...')],
  isLoading: true,
);
```

## Configuration Options

### BubbleConfiguration

- `profileBuilder`: Custom profile widget builder
- `senderBubbleBuilder`: Custom sender bubble builder
- `receiverBubbleBuilder`: Custom receiver bubble builder
- `timeBuilder`: Custom timestamp builder
- `loadingWidget`: Custom loading indicator
- `maxWidth`: Maximum bubble width

### ChatConfiguration

- `senderAlignment`: Message alignment (start/end)
- `customInputField`: Custom input field widget
- `newReceiveMessageNotificationBuilder`: New message notification builder
- `bubbleConfiguration`: Bubble appearance settings
- `newMessageScrollThreshold`: Scroll threshold for new messages

## Requirements

- Flutter SDK: >=1.17.0
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
