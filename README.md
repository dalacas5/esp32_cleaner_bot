# ESP32 Cleaner Bot v1.1

Proyecto de robot de limpieza con **firmware para ESP32-S3** y **aplicación Flutter** para control remoto por **BLE**.

## 🚀 Características

### Firmware (ESP-IDF v5.5)
- ✅ Control BLE GATT (Bluedroid) - Servicio `0x00FF`
- ✅ Control de motores DC vía PWM (LEDC)
- ✅ Bomba de agua con control GPIO
- ✅ LED RGB WS2812 para feedback visual
- ✅ Arquitectura modular con componentes ESP-IDF

### Mobile App (Flutter)
- ✅ Control de tracción con deslizador vertical
- ✅ Control avanzado del rodillo (velocidad + dirección)
- ✅ Bomba de agua ON/OFF
- ✅ Dashboard con estado en tiempo real
- ✅ Throttling BLE optimizado (10 cmd/seg)

## 📁 Estructura del Proyecto

```
esp32_cleaner_bot_v0/
├── firmware/
│   ├── components/          # Componentes modulares
│   │   ├── ble_server/      # Servidor BLE GATT
│   │   ├── motor_control/   # Control PWM motores
│   │   ├── pump_control/    # Control bomba de agua
│   │   └── led/             # Control LED RGB
│   └── main/                # Aplicación principal
├── mobile_app/
│   └── lib/
│       ├── screens/         # Pantallas (Scan, Device)
│       └── widgets/         # Widgets reutilizables (Throttle, etc.)
├── docs/                    # Documentación y diagramas
└── hardware/                # Esquemas eléctricos (opcional)
```

## 🔧 Requisitos

### Firmware
- **ESP-IDF:** v5.5.0
- **Hardware:** ESP32-S3 DevKit
- **Dependencias:** `led_strip` (managed component)

### App
- **Flutter:** >= 3.32.8
- **Paquetes:** `flutter_blue_plus`

## 🛠️ Compilar y Flashear

### Firmware
```bash
cd firmware
idf.py set-target esp32s3
idf.py build
idf.py flash monitor
```

### Mobile App
```bash
cd mobile_app
flutter pub get
flutter run
```

## 📱 Uso de la App

1. **Escanear dispositivos** → Tap en el botón de búsqueda
2. **Conectar** → Selecciona "ESP32_MOTOR_CTRL"
3. **Controles:**
   - **Tracción:** Deslizador vertical (Arriba=Adelante, Abajo=Atrás)
   - **Rodillo:** 
     - Tap corto → ON/OFF rápido
     - Tap largo → Panel de configuración (Velocidad + Dirección)
   - **Agua:** Toggle para bomba
   - **LED:** Toggle para iluminación

## 🔌 Conexiones Hardware

| Componente | GPIO | Tipo |
|------------|------|------|
| **Tracción** | 2 (PWM), 4 (IN1), 5 (IN2) | PWM + Digital |
| **Rodillo** | 6 (PWM), 7 (IN1), 17 (IN2) | PWM + Digital |
| **Bomba** | 15 | Digital |
| **LED RGB** | 38 | WS2812 |

## 📄 Licencia
MIT - Ver archivo `LICENSE`

## 🤝 Contribuciones
Pull requests son bienvenidos. Para cambios mayores, abre primero un issue.
