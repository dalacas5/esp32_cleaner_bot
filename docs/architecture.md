# Arquitectura (resumen)

- **ESP32-S3 (firmware)**: servidor BLE (Bluedroid) que recibe comandos y controla motores DC (PWM/LEDC).
- **App Flutter**: cliente BLE que descubre, se conecta y envía comandos (p. ej., `FWD`, `REV`, `STOP`).

## Endpoints BLE (ejemplo)
- Servicio: 0xFFF0
- Característica TX (periférico<-app): 0xFFF1 (Write)
- Característica RX (periférico->app): 0xFFF2 (Notify)
