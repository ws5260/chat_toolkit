import 'package:flutter/material.dart';

class MessageFailed extends StatelessWidget {
  const MessageFailed({
    super.key,
    required this.onDelete,
    required this.onRetry,
  });
  final Function()? onDelete;
  final Function()? onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5B5B),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete),
          ),
          const SizedBox(
            width: 14,
            height: 20,
            child: VerticalDivider(
              color: Color(0x99FFFFFF),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
