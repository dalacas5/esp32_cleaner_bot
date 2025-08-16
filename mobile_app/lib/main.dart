import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// El código de main(), MotorControllerApp y ScanScreen no cambia
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
      home: ScanScreen(),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results
          .where((r) => r.device.platformName.isNotEmpty)
          .toList();
      if (mounted) setState(() {});
    });
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  void _onDeviceTap(BluetoothDevice device) {
    FlutterBluePlus.stopScan();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Dispositivos BLE')),
      body: ListView.builder(
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final result = _scanResults[index];
          return ListTile(
            title: Text(result.device.platformName),
            subtitle: Text(result.device.remoteId.toString()),
            leading: const Icon(Icons.bluetooth),
            onTap: () => _onDeviceTap(result.device),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _isScanning
            ? FlutterBluePlus.stopScan()
            : FlutterBluePlus.startScan(timeout: const Duration(seconds: 15)),
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}

// --- PANTALLA DE CONTROL (DeviceScreen) - ¡AQUÍ ESTÁN LOS CAMBIOS! ---
// --- PANTALLA DE CONTROL (DeviceScreen) ---
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
  bool _isLedOn = false;

  final List<double> _motorSpeeds = [0, 0, 0, 0];

  final String serviceUuid = "00e0";
  final String ledCharUuid = "ff01";
  final String motorCharUuid = "ff02";

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

  // ESTA FUNCIÓN ESTABA VACÍA EN EL CÓDIGO ANTERIOR
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
          }
        }
      }
    }
    setState(() {});
  }

  // ESTA FUNCIÓN ESTABA VACÍA EN EL CÓDIGO ANTERIOR
  Future<void> _toggleLed(bool value) async {
    if (_ledCharacteristic == null) return;
    await _ledCharacteristic!.write(value ? [0x01] : [0x00]);
    setState(() {
      _isLedOn = value;
    });
  }

  // ESTA FUNCIÓN ESTABA VACÍA EN EL CÓDIGO ANTERIOR
  Future<void> _sendMotorCommand(int id, int direction, int speed) async {
    if (_motorCharacteristic == null) return;
    await _motorCharacteristic!.write([id, direction, speed]);
  }

  String get _connectionStatusText {
    switch (_connectionState) {
      // case BluetoothConnectionState.connecting:
      //   return "Conectando...";
      case BluetoothConnectionState.connected:
        return "Conectado";
      // case BluetoothConnectionState.disconnecting:
      //   return "Desconectando...";
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
            const Divider(),
            // El resto de la UI que ya tenías
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

// --- NUEVO WIDGET REUTILIZABLE para el control de un motor ---
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
