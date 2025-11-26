import 'package:flutter/material.dart';
import 'screens/scan_screen.dart';

void main() => runApp(const MotorControllerApp());

class MotorControllerApp extends StatelessWidget {
  const MotorControllerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motor Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ScanScreen(),
    );
  }
}
