import 'package:flutter/material.dart';

/// Called when the size of a [SizeDetectedWidget] changes.
typedef SizeDetectedCallback = void Function(Size? oldSize, Size? newSize);

/// Which dimension changes a [SizeDetectedWidget] reports.
enum SizeDetectedWidgetType {
  /// Report only height changes.
  height,

  /// Report only width changes.
  width,

  /// Report any size change.
  all,
}

/// Reports size changes of its [child].
class SizeDetectedWidget extends StatefulWidget {
  /// Creates a [SizeDetectedWidget].
  const SizeDetectedWidget({
    super.key,
    required this.onChange,
    required this.child,
    this.type = SizeDetectedWidgetType.all,
  });

  /// Called with the old and new size when the size changes.
  final SizeDetectedCallback onChange;

  /// Which dimension changes to report.
  final SizeDetectedWidgetType type;

  /// The widget whose size is observed.
  final Widget child;

  @override
  State<SizeDetectedWidget> createState() => _SizeDetectedWidgetState();
}

class _SizeDetectedWidgetState extends State<SizeDetectedWidget> {
  Size? oldSize;

  void _onSizeChange(Size newSize) {
    void setSize() {
      widget.onChange(oldSize, newSize);
      oldSize = newSize;
    }

    if (oldSize == null) {
      oldSize = newSize;
      return;
    }

    if (widget.type == SizeDetectedWidgetType.height) {
      if (oldSize!.height != newSize.height) {
        setSize();
      }
    } else if (widget.type == SizeDetectedWidgetType.width) {
      if (oldSize!.width != newSize.width) {
        setSize();
      }
    } else {
      if (oldSize != newSize) {
        setSize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onSizeChange(constraints.biggest);
        });
        return widget.child;
      },
    );
  }
}
