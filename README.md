# ESP32 Cleaner Bot

Proyecto que combina **firmware para ESP32-S3** y una **aplicación Flutter** para controlar motores DC por **BLE**.

## Estructura
- `firmware/` → Código ESP-IDF v5.x (BLE + control de motores).
- `mobile_app/` → App Flutter que actúa como control remoto.
- `docs/` → Documentación, diagramas y capturas.
- `hardware/` → Esquemas eléctricos o PCB (opcional).

## Requisitos
**Firmware**
- ESP-IDF v5.5.0
- ESP32-S3 DevKit

**App**
- Flutter >= 3.32.8
- Android SDK o Xcode

## Compilar
**Firmware**
```bash
cd firmware
idf.py set-target esp32s3
idf.py build flash monitor
```

**Flutter**
```bash
cd mobile_app
flutter pub get
flutter run
```

## Licencia
MIT. Ver `LICENSE`.
