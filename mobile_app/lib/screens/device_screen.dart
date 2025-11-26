import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widgets/motor_control_card.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceScreen({super.key, required this.device});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late StreamSubscription<BluetoothConnectionState>
  _connectionStateSubscription;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  BluetoothCharacteristic? _ledCharacteristic;
  BluetoothCharacteristic? _motorCharacteristic;
  BluetoothCharacteristic? _pumpCharacteristic;
  bool _isLedOn = false;
  bool _isPumpOn = false;

  final List<double> _motorSpeeds = [0, 0, 0, 0];

  final String serviceUuid = "00ff";
  final String ledCharUuid = "ff01";
  final String motorCharUuid = "ff02";
  final String pumpCharUuid = "ff03";

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription = widget.device.connectionState.listen((
      state,
    ) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        await _discoverServices();
      }
      if (mounted) setState(() {});
    });
    widget.device.connect();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  Future<void> _discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == serviceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == ledCharUuid) {
            _ledCharacteristic = characteristic;
            print("¡Característica del LED asignada!");
          } else if (characteristic.uuid.toString() == motorCharUuid) {
            _motorCharacteristic = characteristic;
            print("¡Característica del Motor asignada!");
          } else if (characteristic.uuid.toString() == pumpCharUuid) {
            _pumpCharacteristic = characteristic;
            print("¡Característica de la Bomba asignada!");
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> _toggleLed(bool value) async {
    if (_ledCharacteristic == null) return;
    await _ledCharacteristic!.write(value ? [0x01] : [0x00]);
    setState(() {
      _isLedOn = value;
    });
  }

  Future<void> _togglePump(bool value) async {
    if (_pumpCharacteristic == null) return;
    await _pumpCharacteristic!.write(value ? [0x01] : [0x00]);
    setState(() {
      _isPumpOn = value;
    });
  }

  Future<void> _sendMotorCommand(int id, int direction, int speed) async {
    if (_motorCharacteristic == null) return;
    await _motorCharacteristic!.write([id, direction, speed]);
  }

  String get _connectionStatusText {
    switch (_connectionState) {
      case BluetoothConnectionState.connected:
        return "Conectado";
      default:
        return "Desconectado";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.platformName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Estado: $_connectionStatusText'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Control del LED", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Switch(
                  value: _isLedOn,
                  onChanged: _ledCharacteristic != null ? _toggleLed : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Bomba de Agua", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Switch(
                  value: _isPumpOn,
                  onChanged: _pumpCharacteristic != null ? _togglePump : null,
                ),
              ],
            ),
            const Divider(),
            MotorControlWidget(
              motorId: 0,
              speed: _motorSpeeds[0],
              onCommand: _sendMotorCommand,
              isEnabled: _motorCharacteristic != null,
              onSpeedChanged: (newSpeed) =>
                  setState(() => _motorSpeeds[0] = newSpeed),
            ),
            MotorControlWidget(
              motorId: 1,
              speed: _motorSpeeds[1],
              onCommand: _sendMotorCommand,
              isEnabled: _motorCharacteristic != null,
              onSpeedChanged: (newSpeed) =>
                  setState(() => _motorSpeeds[1] = newSpeed),
            ),
            MotorControlWidget(
              motorId: 2,
              speed: _motorSpeeds[2],
              onCommand: _sendMotorCommand,
              isEnabled: _motorCharacteristic != null,
              onSpeedChanged: (newSpeed) =>
                  setState(() => _motorSpeeds[2] = newSpeed),
            ),
            MotorControlWidget(
              motorId: 3,
              speed: _motorSpeeds[3],
              onCommand: _sendMotorCommand,
              isEnabled: _motorCharacteristic != null,
              onSpeedChanged: (newSpeed) =>
                  setState(() => _motorSpeeds[3] = newSpeed),
            ),
          ],
        ),
      ),
    );
  }
}
