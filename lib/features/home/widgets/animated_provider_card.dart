import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedProviderCard extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedProviderCard({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedProviderCard> createState() => _AnimatedProviderCardState();
}

class _AnimatedProviderCardState extends State<AnimatedProviderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 700 + (widget.index * 150),
      ),
    );

    Future.delayed(
      Duration(milliseconds: widget.index * 120),
      () => controller.forward(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(
          controller.value,
        );

        // Floating effect using sin wave
        final floatOffset = sin(controller.value * pi * 2) * 3;

        return Transform.translate(
          offset: Offset(0, (40 * (1 - value)) + floatOffset),
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}