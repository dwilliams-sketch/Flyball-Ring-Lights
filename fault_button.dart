import 'package:flutter/material.dart';

class FaultButton extends StatelessWidget {
  final int dogNumber;
  final Color laneColor;
  final bool active;
  final VoidCallback onTap;
  final double width;
  final double height;
  final double fontSize;

  const FaultButton({
    super.key,
    required this.dogNumber,
    required this.laneColor,
    required this.active,
    required this.onTap,
    this.width = 78,
    this.height = 58,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final radius = (height * .24).clamp(10.0, 16.0);

    return Semantics(
      button: true,
      label: 'Dog $dogNumber fault',
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: active
                ? laneColor
                : laneColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: active
                  ? Colors.white70
                  : laneColor.withValues(alpha: .45),
              width: active ? 2 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: laneColor.withValues(alpha: .55),
                      blurRadius: (height * .28).clamp(8.0, 18.0),
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Center(
            child: Text(
              '$dogNumber',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: active ? Colors.white : laneColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
