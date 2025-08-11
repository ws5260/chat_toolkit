import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class MessageLoading extends StatefulWidget {
  const MessageLoading({super.key});

  @override
  State<MessageLoading> createState() => _MessageLoadingState();
}

class _MessageLoadingState extends State<MessageLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value * pi;

        final color1 = _getColor(progress);
        final color2 = _getColor(progress * 2);
        final color3 = _getColor(progress * 3);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleAvatar(color1),
            const Gap(4),
            _buildCircleAvatar(color2),
            const Gap(4),
            _buildCircleAvatar(color3),
          ],
        );
      },
    );
  }

  Color _getColor(double progress) {
    return Color.lerp(
      const Color(0xFFCCCCCC),
      const Color(0xFFF1F1F1),
      sin(progress),
    )!;
  }

  CircleAvatar _buildCircleAvatar(
    Color? color,
  ) {
    return CircleAvatar(
      radius: 4,
      backgroundColor: color,
    );
  }
}
