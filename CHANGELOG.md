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

## 1.5.0

### Added

- `ChatController(additionalGroupCondition: ...)`: optional `AdditionalGroupCondition` callback that adds your own condition for whether a message joins an existing message group. It is applied on top of the default condition.
- `ChatController.defaultCanJoinGroup`: the default grouping condition (same sender, same name, same minute).

### Changed

- Messages are now grouped only when the sender name is also the same (previously only `isSender` and the minute were compared).
- Failed messages that are moved to the end now follow the same grouping condition instead of only comparing `isSender`.

---

## 1.5.0 (한국어)

### 추가

- `ChatController(additionalGroupCondition: ...)`: 메시지를 기존 묶음에 합칠지 결정하는 조건을 직접 추가할 수 있는 `AdditionalGroupCondition` 콜백(선택). 기본 조건에 더해 적용됩니다.
- `ChatController.defaultCanJoinGroup`: 기본 묶음 조건(같은 발신자, 같은 이름, 같은 분)입니다.

### 변경

- 발신자 이름까지 같을 때만 메시지를 묶습니다(기존에는 `isSender`와 분만 비교).
- 맨 뒤로 이동하는 실패 메시지도 `isSender`만 비교하지 않고 동일한 묶음 조건을 따릅니다.

## 1.5.1

### Changed

- The message list now uses `SuperSliverList` from the [`super_sliver_list`](https://pub.dev/packages/super_sliver_list) package instead of `SliverList`, for more accurate scroll extent estimation and smoother scrolling with variable-height messages.

### Added

- New dependency: `super_sliver_list`.

---

## 1.5.1 (한국어)

### 변경

- 메시지 목록이 `SliverList` 대신 [`super_sliver_list`](https://pub.dev/packages/super_sliver_list) 패키지의 `SuperSliverList`를 사용합니다. 높이가 제각각인 메시지에서도 스크롤 범위를 더 정확히 계산해 스크롤이 더 부드럽습니다.

### 추가

- 새 의존성: `super_sliver_list`.

## 1.6.0

### Added

- **Bubble context menu**: a long press on a message bubble opens a menu — a held touch, or a held mouse button on desktop and web. Sender and receiver menus are configured separately through `BubbleConfiguration(menuConfiguration: BubbleMenuConfiguration(...))`.
  - `senderItemsBuilder` / `receiverItemsBuilder`: entries of the default popup menu for each side. A side without a builder has no menu; returning an empty list suppresses the menu for that message.
  - `senderMenuHandler` / `receiverMenuHandler`: present a fully custom menu (bottom sheet, dialog, overlay) instead of the default popup for that side.
  - `BubbleMenuItem`: a menu entry with `label`, `icon`, `child`, `enabled`, `textStyle`, `height`, `padding`, and an `onSelected` callback.
  - `BubbleMenuRequest`: passed to every menu callback with the `message`, `isSender`, the pointer's `globalPosition`, and the bubble's global `bubbleRect`.
  - Trigger and style options: `enableLongPress`, `enableHapticFeedback`, `color`, `surfaceTintColor`, `shape`, `elevation`, `constraints`, `useRootNavigator`.
  - `animationStyle`: retimes the default menu's open/close transition (duration, curve, reverse curve), or `AnimationStyle.noAnimation` to show it instantly. For a different kind of transition, use a menu handler.
  - `showBubbleMenu(...)` is exported for opening the default menu yourself.
- `MessageElement` is now exported from `package:chat_toolkit/chat_toolkit.dart`, so custom elements no longer need a deep import.

### Changed

- The example app now demonstrates the bubble menu (different entries for sent and received messages), adds a working input field, and ships real widget tests instead of the default counter test.

### Notes

- The menu is opt-in: without `menuConfiguration`, bubble gestures are unchanged.
- Right click is deliberately not a trigger: on Flutter web it would open the browser's own context menu at the same time. Holding the mouse button counts as a long press, so desktop and web users still get the menu.

---

## 1.6.0 (한국어)

### 추가

- **말풍선 컨텍스트 메뉴**: 말풍선을 길게 누르면 메뉴가 열립니다(터치 꾹 누르기, 데스크톱·웹에서는 마우스 버튼 꾹 누르기). 보낸 사람과 받는 사람 메뉴를 `BubbleConfiguration(menuConfiguration: BubbleMenuConfiguration(...))`에서 각각 따로 설정합니다.
  - `senderItemsBuilder` / `receiverItemsBuilder`: 각 방향의 기본 팝업 메뉴 항목입니다. 빌더가 없는 쪽은 메뉴가 열리지 않고, 빈 리스트를 반환하면 해당 메시지에서만 메뉴가 열리지 않습니다.
  - `senderMenuHandler` / `receiverMenuHandler`: 기본 팝업 대신 바텀시트·다이얼로그 등 원하는 UI를 직접 띄울 수 있습니다.
  - `BubbleMenuItem`: `label`, `icon`, `child`, `enabled`, `textStyle`, `height`, `padding`과 `onSelected` 콜백을 가진 메뉴 항목입니다.
  - `BubbleMenuRequest`: 메뉴 콜백에 전달되며 `message`, `isSender`, 포인터의 `globalPosition`, 말풍선의 전역 좌표 `bubbleRect`를 담고 있습니다.
  - 동작·스타일 옵션: `enableLongPress`, `enableHapticFeedback`, `color`, `surfaceTintColor`, `shape`, `elevation`, `constraints`, `useRootNavigator`.
  - `animationStyle`: 기본 메뉴가 열리고 닫히는 속도·커브를 조절합니다(`AnimationStyle.noAnimation`이면 즉시 표시). 트랜지션 종류 자체를 바꾸려면 메뉴 핸들러를 쓰세요.
  - 기본 메뉴를 직접 띄울 수 있도록 `showBubbleMenu(...)`도 함께 공개됩니다.
- `MessageElement`를 `package:chat_toolkit/chat_toolkit.dart`에서 바로 export 합니다. 커스텀 엘리먼트를 만들 때 내부 경로를 직접 import 하지 않아도 됩니다.

### 변경

- 예제 앱이 말풍선 메뉴(보낸 메시지와 받은 메시지에 서로 다른 항목)를 보여주고, 동작하는 입력창이 추가되었으며, 기본 카운터 테스트 대신 실제 위젯 테스트를 포함합니다.

### 참고

- 선택 기능입니다. `menuConfiguration`을 설정하지 않으면 말풍선 제스처는 기존과 동일합니다.
- 우클릭은 의도적으로 트리거에서 제외했습니다. Flutter 웹에서는 브라우저 기본 컨텍스트 메뉴가 함께 뜨기 때문입니다. 마우스 버튼을 꾹 누르면 길게 누르기로 인식되므로 데스크톱·웹에서도 메뉴를 쓸 수 있습니다.

---

## 1.6.1

### Fixed

- **Bubble menu position**: the pointer's `globalPosition` is now converted into the Overlay's local coordinates before anchoring the menu. When the Overlay is transformed — scaled or offset by a `FittedBox`, a zoomed view, and so on — the menu used to open away from the bubble.

### Changed

- Internal formatting and readability cleanup in `bubble_menu.dart`. No public API change.

---

## 1.6.1 (한국어)

### 수정

- **말풍선 메뉴 위치**: 포인터의 `globalPosition`을 Overlay의 로컬 좌표로 변환한 뒤 메뉴를 띄우도록 고쳤습니다. `FittedBox`나 확대·축소된 화면처럼 Overlay에 변환이 걸려 있으면 메뉴가 말풍선에서 벗어난 위치에 열리던 문제가 있었습니다.

### 변경

- `bubble_menu.dart` 내부 포맷·가독성 정리. 공개 API 변경은 없습니다.

---

## 1.6.2

### Added

- **API documentation**: every public class, field, method and typedef now has a dartdoc comment, so the API reference on pub.dev shows descriptions, default values and usage examples.
  - Library overview with a quick-start example.
  - Examples for `Chat`, `MessageElement` and `ChatController.dispatchMessage`.
- Enabled the `public_member_api_docs` lint so new public members must be documented.

### Changed

- No code or public API changes.

---

## 1.6.2 (한국어)

### 추가

- **API 문서**: 모든 public 클래스, 필드, 메서드, typedef에 dartdoc 주석을 추가했습니다. 이제 pub.dev API 레퍼런스에 설명, 기본값, 사용 예제가 표시됩니다.
  - 라이브러리 개요와 빠른 시작 예제.
  - `Chat`, `MessageElement`, `ChatController.dispatchMessage` 예제.
- `public_member_api_docs` lint를 활성화해 새 public 멤버에 주석이 없으면 경고가 뜨도록 했습니다.

### 변경

- 코드 동작과 공개 API 변경은 없습니다.
