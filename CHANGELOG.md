## 1.0.0

### Added

- **Core Chat Widget**: Complete chat interface with message display and input functionality
- **Message System**:
  - Support for sender and receiver message types
  - Message elements architecture for extensible content types
  - Message grouping functionality for better organization
  - Unique message ID generation using UUID
  - Message state management (loading, failed, success)
- **Chat Controller**:
  - Scroll controller with chat-specific functionality
  - Message dispatch system with result callbacks
  - Stream-based message handling for real-time updates
  - Failed message retry mechanism
  - Collapsible chat state management
- **Customizable UI Components**:
  - Configurable message bubbles with sender/receiver styling
  - Customizable profile display with avatar and name
  - Flexible timestamp rendering
  - Loading state indicators
  - Input field with emoji and send button support
- **Configuration Options**:
  - Chat alignment settings (start/end positioning)
  - Custom input field support
  - New message notification builders
  - Bubble appearance customization
  - Scroll threshold configuration for new messages
- **Read-Only Mode**: Support for display-only chat interfaces
- **Responsive Design**: Auto-sizing widgets with width detection
- **Internationalization**: Built-in support with intl package
- **Memory Management**: Proper disposal patterns and lifecycle management

### Dependencies

- Flutter SDK >=3.24.0
- Dart SDK ^3.5.0
- gap: ^3.0.1 (spacing utilities)
- intl: ^0.19.0 (internationalization)
- uuid: ^4.5.1 (unique ID generation)

## 1.1.0

### Added

- **Date Separator Builder**: Date Separator Custom Builder

## 1.1.1

### FIXED

fix: Add missing filename configuration for web platform

- Fix missing filename property in pubspec.yaml web platform configuration
- Resolves pub.dev analysis warning about web platform setup

## 1.1.2

### FIXED

- Remove plugin in pubspec.yaml web platform configuration

## 1.2.0

### Added

- **Message Bubble Time Builder**: Message Bubble timestamp custom builder

## 1.3.0

- **Read Only Custom Widget**: Added a read-only widget that displays when the chat is in read-only mode

## 1.3.1

- **Remove Reverse Setting**: Removed the reverse parameter from ChatController configuration

## 1.3.2

- Fix: Apply missing changes that were accidentally not included in the previous release

## 1.3.3

### Added

- **ChatController Custom Sorting**: Added a message custom sorting feature

### Fix

- Add loading message sorting to message prioritization logic

## 1.3.4

### Fix

- Remove default input field and add custom input field parameter to Chat widget
- Update withOpacity to withValues


## 1.3.5

### Added

- Added separate sender and receiver profile builders to `BubbleConfiguration`.
- Added customizable read indicators for message bubbles.
- Added methods for managing message read states and updating message visibility.

### Changed

- Simplified message dispatch logic in `ChatController`.
- Improved unread message handling.
- Streamlined message grouping and sorting for better performance.
- Improved code readability across multiple files.

### Removed

- Removed unnecessary comments and redundant code.

## 1.3.6

### Changed

- `intl` package upgrade

## 1.4.0

### Performance

- Scrolling no longer rebuilds the whole message list; only message groups entering the viewport are built. In a 300-message room, janky frames dropped from 11–79% to 0–4%, and build time (p90) from 11.6–21.6ms to 4.7–6.3ms.
- Added `ChatController.messagesRevision` (`ValueListenable<int>`), which changes only when the message list changes. `Chat` listens to it instead of the controller, which notifies on every scroll offset change. `notifyListeners()` is still called, so existing controller listeners behave as before.

### Added

- `MessageBlockedException`: throw it from an `onDispatch` callback when the server blocks sending. The bubble is removed and no retry entry is created. The dispatch result stream still receives a result with `isSuccess: false`.
- `ChatController.registerFailedMessage`: registers a failed message loaded from history as retryable.
- `Chat.onDeleteFailedMessage`: called when the delete button on a failed bubble is tapped. The message is removed only if it returns `true`; if omitted, it is removed locally.
- `ChatConfiguration.padding`: list padding (default: horizontal 30, same as before).
- `Message.serverUuid`: optional server-side identifier, preserved by `copyWith`.
- `MessageBubble.showTime` / `MessageContainer.showTime`: when `false`, the timestamp is hidden. `Chat` now shows the time only on the last message of each group.
- Failed bubble buttons now have a tooltip and accessibility label.

### Changed

- Loading older messages when the messages do not fill the screen: `onScrollToTop` is now called repeatedly until the screen is filled (previously it was never called because the list could not scroll). Oldest-end detection now also handles non-reversed lists.
- `addMessage` replaces an existing message with the same non-empty `id` instead of adding a duplicate.
- `scrollToBottom` no longer animates and does nothing if already at the bottom. `scrollToTopByValue` / `scrollToBottomByValue` now respect the `reverse` mode.
- Sending a message (`isSender`) scrolls to the bottom.
- Failed bubble UI: the retry icon now comes first and the delete icon is now an X; sizes follow the new design spec.
- Minimum Dart SDK raised to `^3.12.0`.

### Fix

- Fixed a potential null-check crash on `oldSize` in the size-change handler.
- `_onScroll` checks `mounted` and `hasClients` before reading the scroll position.

---

## 1.4.0 (한국어)

### 성능 개선

- 스크롤할 때 메시지 목록 전체를 다시 만들지 않고, 화면에 보이는 메시지 묶음만 만듭니다. 메시지 300개 기준으로 끊기는 프레임이 11~79%에서 0~4%로, build 시간(p90)이 11.6~21.6ms에서 4.7~6.3ms로 줄었습니다.
- `ChatController.messagesRevision`(`ValueListenable<int>`)을 추가했습니다. 메시지 목록이 바뀔 때만 값이 바뀌며, `Chat`은 스크롤할 때마다 알림을 보내는 컨트롤러 대신 이 값을 구독합니다. `notifyListeners()`는 그대로 호출하므로 기존 컨트롤러 리스너 동작은 같습니다.

### 추가

- `MessageBlockedException`: 서버가 발신을 차단했을 때 `onDispatch`에서 던집니다. 말풍선을 지우고 재전송 항목은 만들지 않습니다. 전송 결과 스트림에는 `isSuccess: false` 결과가 전달됩니다.
- `ChatController.registerFailedMessage`: 이력에서 불러온 실패 메시지를 재전송 대상으로 등록합니다.
- `Chat.onDeleteFailedMessage`: 실패 말풍선의 삭제 버튼을 누르면 호출됩니다. `true`를 반환해야 메시지가 지워지며, 지정하지 않으면 로컬에서만 지웁니다.
- `ChatConfiguration.padding`: 목록 패딩 (기본값 좌우 30, 기존과 동일).
- `Message.serverUuid`: 서버 측 식별자(선택). `copyWith`에서 유지됩니다.
- `MessageBubble.showTime` / `MessageContainer.showTime`: `false`면 시간을 숨깁니다. `Chat`은 이제 묶음의 마지막 메시지에만 시간을 표시합니다.
- 실패 말풍선 버튼에 툴팁과 접근성 라벨을 추가했습니다.

### 변경

- 메시지가 화면을 다 채우지 못할 때 과거 메시지 불러오기: 목록이 스크롤되지 않아 `onScrollToTop`이 불리지 않던 문제를 고쳐, 화면이 찰 때까지 반복해서 호출합니다. 과거 끝 판정은 뒤집히지 않은 목록도 지원합니다.
- `addMessage`: 비어 있지 않은 `id`가 이미 있으면 중복 추가하지 않고 기존 메시지를 교체합니다.
- `scrollToBottom`은 애니메이션 없이 이동하며, 이미 맨 아래면 아무것도 하지 않습니다. `scrollToTopByValue` / `scrollToBottomByValue`는 `reverse` 모드를 따릅니다.
- 메시지를 보내면(`isSender`) 맨 아래로 스크롤합니다.
- 실패 말풍선 UI: 재전송 아이콘이 앞으로 오고 삭제 아이콘은 X로 바뀌었으며, 크기는 새 시안을 따릅니다.
- 최소 Dart SDK를 `^3.12.0`으로 올렸습니다.

### 수정

- 크기 변경 처리에서 `oldSize` null 체크로 발생할 수 있던 크래시를 고쳤습니다.
- `_onScroll`이 스크롤 위치를 읽기 전에 `mounted`와 `hasClients`를 확인합니다.
