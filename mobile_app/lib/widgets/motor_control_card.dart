import 'package:flutter/material.dart';

class MotorControlWidget extends StatelessWidget {
  final int motorId;
  final double speed; // 0.0 to 255.0
  final bool isEnabled;
  final Function(int id, int direction, int speed) onCommand;
  final Function(double newSpeed) onSpeedChanged;

  const MotorControlWidget({
    super.key,
    required this.motorId,
    required this.speed,
    required this.isEnabled,
    required this.onCommand,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Motor ${motorId + 1}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // Slider para la velocidad
            Slider(
              value: speed,
              min: 0,
              max: 255,
              divisions: 255,
              label: speed.round().toString(),
              onChanged: isEnabled ? onSpeedChanged : null,
            ),
            const SizedBox(height: 8),
            // Botones para la dirección
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: isEnabled
                      ? () => onCommand(motorId, 0, speed.toInt())
                      : null,
                  child: const Text("Adelante"),
                ),
                ElevatedButton(
                  onPressed: isEnabled ? () => onCommand(motorId, 0, 0) : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Parar"),
                ),
                ElevatedButton(
                  onPressed: isEnabled
                      ? () => onCommand(motorId, 1, speed.toInt())
                      : null,
                  child: const Text("Atrás"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
