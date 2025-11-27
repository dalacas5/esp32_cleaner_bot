import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widgets/throttle_widget.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceScreen({super.key, required this.device});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  BluetoothCharacteristic? _ledCharacteristic;
  BluetoothCharacteristic? _motorCharacteristic;
  BluetoothCharacteristic? _pumpCharacteristic;
  
  bool _isLedOn = false;
  bool _isPumpOn = false;
  bool _isRollerOn = false;
  double _rollerSpeed = 200; // Default speed (0-255)
  int _rollerDirection = 0; // 0: Forward/Clockwise, 1: Reverse/Counter-clockwise
  
  // Throttle control state
  double _currentThrottleValue = 0.0;
  double _lastSentThrottleValue = 0.0;
  Timer? _throttleTimer;
  int _currentSpeed = 0; // 0-100%

  final String serviceUuid = "00ff";
  final String ledCharUuid = "ff01";
  final String motorCharUuid = "ff02";
  final String pumpCharUuid = "ff03";

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription = widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        await _discoverServices();
      }
      if (mounted) setState(() {});
    });
    widget.device.connect();
    
    // Initialize throttle timer (10 commands per second max)
    _throttleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentThrottleValue != _lastSentThrottleValue) {
        _sendThrottleCommand(_currentThrottleValue);
        _lastSentThrottleValue = _currentThrottleValue;
      }
    });
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
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
          } else if (characteristic.uuid.toString() == motorCharUuid) {
            _motorCharacteristic = characteristic;
          } else if (characteristic.uuid.toString() == pumpCharUuid) {
            _pumpCharacteristic = characteristic;
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> _toggleLed(bool value) async {
    if (_ledCharacteristic == null) return;
    await _ledCharacteristic!.write(value ? [0x01] : [0x00]);
    setState(() => _isLedOn = value);
  }

  Future<void> _togglePump(bool value) async {
    if (_pumpCharacteristic == null) return;
    await _pumpCharacteristic!.write(value ? [0x01] : [0x00]);
    setState(() => _isPumpOn = value);
  }

  Future<void> _toggleRoller(bool value) async {
    setState(() {
      _isRollerOn = value;
    });
    if (value) {
      await _sendMotorCommand(1, _rollerDirection, _rollerSpeed.toInt());
    } else {
      await _sendMotorCommand(1, 0, 0); // Stop
    }
  }

  void _showRollerSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Configuración del Rodillo",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  
                  // Speed Control
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.purple),
                      const SizedBox(width: 10),
                      const Text("Velocidad:", style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Text(
                        "${(_rollerSpeed / 255 * 100).round()}%",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                    ],
                  ),
                  Slider(
                    value: _rollerSpeed,
                    min: 0,
                    max: 255,
                    divisions: 51,
                    activeColor: Colors.purple,
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _rollerSpeed = value;
                        });
                      });
                      if (_isRollerOn) {
                        _sendMotorCommand(1, _rollerDirection, _rollerSpeed.toInt());
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Direction Control
                  Row(
                    children: [
                      const Icon(Icons.rotate_right, color: Colors.purple),
                      const SizedBox(width: 10),
                      const Text("Dirección:", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _rollerDirection == 0 ? Colors.purple : Colors.grey[200],
                            foregroundColor: _rollerDirection == 0 ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.rotate_right),
                          label: const Text("Horario"),
                          onPressed: () {
                            setModalState(() {
                              setState(() {
                                _rollerDirection = 0;
                              });
                            });
                            if (_isRollerOn) {
                              _sendMotorCommand(1, _rollerDirection, _rollerSpeed.toInt());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _rollerDirection == 1 ? Colors.purple : Colors.grey[200],
                            foregroundColor: _rollerDirection == 1 ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.rotate_left),
                          label: const Text("Antihorario"),
                          onPressed: () {
                            setModalState(() {
                              setState(() {
                                _rollerDirection = 1;
                              });
                            });
                            if (_isRollerOn) {
                              _sendMotorCommand(1, _rollerDirection, _rollerSpeed.toInt());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cerrar", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendMotorCommand(int id, int direction, int speed) async {
    if (_motorCharacteristic == null) return;
    await _motorCharacteristic!.write([id, direction, speed]);
  }

  void _handleThrottle(double value) {
    // Store the value, timer will send it periodically
    setState(() {
      _currentThrottleValue = value;
      _currentSpeed = (value.abs() * 100).round();
    });
  }
  
  void _sendThrottleCommand(double value) {
    // Actually send the BLE command
    int speed = (value.abs() * 255).toInt();
    int direction = (value >= 0) ? 0 : 1; // 0: Forward, 1: Backward
    _sendMotorCommand(0, direction, speed);
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = _connectionState == BluetoothConnectionState.connected;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.device.platformName, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: isConnected ? Colors.blue : Colors.grey,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // --- DASHBOARD ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCard("Estado", isConnected ? "Listo" : "Desconectado", isConnected ? Colors.green : Colors.red),
                _buildStatusCard("Velocidad", "$_currentSpeed%", _currentSpeed > 0 ? Colors.blue : Colors.grey),
                _buildStatusCard("Modo", "Manual", Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- THROTTLE AREA ---
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RotatedBox(quarterTurns: 3, child: Text("VELOCIDAD", style: TextStyle(color: Colors.grey, letterSpacing: 1.5))),
                  const SizedBox(width: 20),
                  ThrottleWidget(
                    onThrottleChange: _handleThrottle,
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          // --- ACTION BUTTONS ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.cleaning_services,
                      label: "RODILLO",
                      isActive: _isRollerOn,
                      onTap: () => _toggleRoller(!_isRollerOn),
                      onLongPress: _showRollerSettings,
                      activeColor: Colors.purple,
                    ),
                    _buildActionButton(
                      icon: Icons.water_drop,
                      label: "AGUA",
                      isActive: _isPumpOn,
                      onTap: () => _togglePump(!_isPumpOn),
                      activeColor: Colors.cyan,
                    ),
                    _buildActionButton(
                      icon: Icons.lightbulb,
                      label: "LED",
                      isActive: _isLedOn,
                      onTap: () => _toggleLed(!_isLedOn),
                      activeColor: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.blue),
                    const SizedBox(width: 8),
                    Icon(Icons.circle, size: 8, color: Colors.grey[300]),
                    const SizedBox(width: 8),
                    Icon(Icons.circle, size: 8, color: Colors.grey[300]),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Icon(icon, color: isActive ? Colors.white : Colors.grey[600], size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isActive ? activeColor : Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
