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