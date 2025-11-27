import 'dart:math';
import 'package:flutter/material.dart';

class JoystickWidget extends StatefulWidget {
  final Function(double degrees, double distance) onJoystickChange;
  final double size;
  final Color innerColor;
  final Color outerColor;

  const JoystickWidget({
    super.key,
    required this.onJoystickChange,
    this.size = 200,
    this.innerColor = Colors.blueAccent,
    this.outerColor = Colors.grey,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  Offset _knobPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _knobPosition = Offset(widget.size / 2, widget.size / 2);
  }

  void _updateKnobPosition(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size / 2;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    double newDx = dx;
    double newDy = dy;

    if (distance > radius) {
      final angle = atan2(dy, dx);
      newDx = cos(angle) * radius;
      newDy = sin(angle) * radius;
    }

    setState(() {
      _knobPosition = Offset(center.dx + newDx, center.dy + newDy);
    });

    // Calculate normalized values (0 to 1)
    final normalizedDistance = min(distance / radius, 1.0);
    final angleDegrees = (atan2(newDy, newDx) * 180 / pi);
    
    widget.onJoystickChange(angleDegrees, normalizedDistance);
  }

  void _resetKnob() {
    setState(() {
      _knobPosition = Offset(widget.size / 2, widget.size / 2);
    });
    widget.onJoystickChange(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final knobSize = widget.size * 0.3;

    return GestureDetector(
      onPanUpdate: (details) => _updateKnobPosition(details.localPosition),
      onPanEnd: (_) => _resetKnob(),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.outerColor.withOpacity(0.3),
        ),
        child: Stack(
          children: [
            Positioned(
              left: _knobPosition.dx - knobSize / 2,
              top: _knobPosition.dy - knobSize / 2,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.innerColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
