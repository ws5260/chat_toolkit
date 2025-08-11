import 'package:flutter/material.dart';

typedef SizeDetectedCallback = void Function(Size? oldSize, Size? newSize);

enum SizeDetectedWidgetType {
  height,
  width,
  all,
}

class SizeDetectedWidget extends StatefulWidget {
  const SizeDetectedWidget({
    super.key,
    required this.onChange,
    required this.child,
    this.type = SizeDetectedWidgetType.all,
  });
  final SizeDetectedCallback onChange;
  final SizeDetectedWidgetType type;
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
