import 'package:flutter/material.dart';

class ThrottleWidget extends StatefulWidget {
  final Function(double value) onThrottleChange; // value from -1.0 to 1.0
  final double width;
  final double height;
  final Color activeColor;
  final Color inactiveColor;

  const ThrottleWidget({
    super.key,
    required this.onThrottleChange,
    this.width = 80,
    this.height = 300,
    this.activeColor = Colors.blueAccent,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<ThrottleWidget> createState() => _ThrottleWidgetState();
}

class _ThrottleWidgetState extends State<ThrottleWidget> {
  double _currentValue = 0.0; // -1.0 (Full Back) to 1.0 (Full Forward)

  void _updateThrottle(double localY) {
    // localY is 0 at top, height at bottom
    // We want: Top = 1.0, Center = 0.0, Bottom = -1.0
    
    double normalized = 1.0 - (2.0 * localY / widget.height);
    
    // Clamp values
    if (normalized > 1.0) normalized = 1.0;
    if (normalized < -1.0) normalized = -1.0;

    // Add a deadzone at center for easier stopping
    if (normalized.abs() < 0.1) normalized = 0.0;

    setState(() {
      _currentValue = normalized;
    });
    widget.onThrottleChange(_currentValue);
  }

  void _resetThrottle() {
    setState(() {
      _currentValue = 0.0;
    });
    widget.onThrottleChange(0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) => _updateThrottle(details.localPosition.dy),
      onVerticalDragEnd: (_) => _resetThrottle(),
      onTapUp: (_) => _resetThrottle(), // Tap to stop
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.inactiveColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(widget.width / 2),
          border: Border.all(color: widget.inactiveColor, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Line
            Container(
              width: widget.width - 20,
              height: 2,
              color: Colors.black26,
            ),
            // Fill Indicator (from center to current value)
            Positioned(
              bottom: _currentValue >= 0 ? widget.height / 2 : null,
              top: _currentValue < 0 ? widget.height / 2 : null,
              height: (_currentValue.abs() * widget.height / 2),
              child: Container(
                width: widget.width - 20,
                decoration: BoxDecoration(
                  color: widget.activeColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // The Knob with percentage
            Positioned(
              top: (widget.height / 2) - (_currentValue * widget.height / 2) - 20,
              child: Container(
                width: widget.width - 10,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.activeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    "${(_currentValue.abs() * 100).round()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Labels
            const Positioned(top: 10, child: Text("FWD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            const Positioned(bottom: 10, child: Text("REV", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}
