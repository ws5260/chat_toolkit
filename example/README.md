# chat_toolkit example

A small demo app for the [`chat_toolkit`](../) package.

## Run

```bash
cd example
flutter run
```

## What it shows

| Feature | Where |
| --- | --- |
| Custom sender / receiver bubbles | `BubbleConfiguration(senderBubbleBuilder:, receiverBubbleBuilder:)` |
| Custom timestamp format | `BubbleConfiguration(timeBuilder:)` |
| **Bubble context menu, different per side** | `BubbleConfiguration(menuConfiguration:)` |
| Custom input field | `Chat(customInputField:)` |
| Async send with an auto reply | `chatController.dispatchMessage(...)` |
| Custom message element | `TextMessageElement` in `lib/main.dart` |

## Bubble context menu

Long press a bubble — a held touch, or a held mouse button in the browser — to open its menu. The two sides are configured separately, so they offer different entries:

- **Sent messages**: 복사 / 재전송 (enabled only for failed messages) / 삭제
- **Received messages**: 복사 / 답장 / 신고

The menu is styled to read like a web dropdown rather than a mobile sheet — 6px radius, 1px border, elevation 2, 32px rows, 13px text, and `AnimationStyle.noAnimation` so it appears instantly. All of that is plain `BubbleMenuConfiguration` / `BubbleMenuItem` options; see `_bubbleMenu` in `lib/main.dart`.

```dart
BubbleConfiguration(
  menuConfiguration: BubbleMenuConfiguration(
    senderItemsBuilder: (context, request) => [...],
    receiverItemsBuilder: (context, request) => [...],
  ),
)
```

To present your own UI instead of the default popup (bottom sheet, dialog, overlay), use `senderMenuHandler` / `receiverMenuHandler`.

> Right click is not a trigger, so the browser's own context menu never collides with the bubble menu on web.

## Tests

```bash
cd example
flutter test
```
