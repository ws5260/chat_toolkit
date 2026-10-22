import 'package:flutter/material.dart';

// Retry/delete action pair attached to a bubble whose send failed.
class MessageFailed extends StatelessWidget {
  const MessageFailed({
    super.key,
    required this.onDelete,
    required this.onRetry,
  });
  final Function()? onDelete;
  final Function()? onRetry;

  static const double _iconSize = 20;
  static const double _height = 28;

  Widget _buildIcon(IconData icon, String label, VoidCallback? onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: Icon(icon, size: _iconSize, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5B5B),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(Icons.refresh, "다시 보내기", onRetry),
          // The 20px-wide box centers the 1px line; per the design spec the line is 16px tall.
          const SizedBox(
            width: 20,
            height: 16,
            child: VerticalDivider(
              width: 20,
              thickness: 1,
              color: Color(0x99FFFFFF),
            ),
          ),
          _buildIcon(Icons.close, "삭제", onDelete),
        ],
      ),
    );
  }
}
