    * **Mecánica:** Transmisión piñón-cadena.
    * **Electrónica:** Señales de control bifurcadas a 2x Drivers L298N en paralelo.
    * **Pines ESP32-S3:** PWM (GPIO 2), IN1 (GPIO 4), IN2 (GPIO 5).
    * **Canal LEDC:** 0

2.  **Sistema de Limpieza (Motor 1 - Lógico):**
    * **Función:** Rotación del rodillo de limpieza.
    * **Mecánica:** Acople directo eje-motor a eje-rodillo.
    * **Electrónica:** 1x Driver L298N.
    * **Pines ESP32-S3:** PWM (GPIO 6), IN1 (GPIO 7), IN2 (GPIO 17). *(Confirmados OK)*.
    * **Canal LEDC:** 1

3.  **Sistema de Humidificación (Nuevo):**
    * **Función:** Rociar agua/líquido de limpieza sobre los espejos.
    * **Hardware:** Bomba de agua 12 VDC + 2 Aspersores.
    * **Control:** Módulo Relé de 3.3 VDC (Activo en Alto o Bajo según módulo) o MOSFET.
    * **Pin ESP32-S3 Sugerido:** **GPIO 15** (Salida Digital).

### Sensores (Pendientes de integración)
* **Navegación (Encoders):** En eje de tracción para medir distancia relativa.
* **Referencia (Hall):** Inicio/Fin de fila (Digital). Inmunes al polvo.
* **Seguridad (IR 5V):** Detección de vacío/vuelco en Eje 2. **Requieren Level Shifter o Divisor de Voltaje (5V -> 3.3V).**

## 3. Arquitectura del Firmware (ESP32-S3)

### Estructura de Archivos
* `main/main.c`: Orquestador principal. Inicializa NVS y componentes.
* `components/ble_server`: Gestión de comunicaciones BLE GATT (Bluedroid).
* `components/motor_control`: Gestión de PWM (LEDC) para Tracción y Rodillo.
* `components/pump_control` (Futuro): Gestión del GPIO del Relé.
* `components/led`: Feedback visual (WS2812).
* `CMakeLists.txt`: Configuración de build mínimo.

### Especificaciones BLE (GATT Server)
* **Nombre Dispositivo:** `RobotCleanerBLE`
* **Servicio Principal:** `0x00FF` (Alineado con App).
* **Características:**
    1.  **LED:** `0xFF01` (Escritura 1 byte: `0x01`/`0x00`).
    2.  **Motores:** `0xFF02` (Escritura 3 bytes: `[ID, Dir, Vel]`).
        * *ID 0:* Tracción.
        * *ID 1:* Rodillo.
    3.  **Bomba:** `0xFF03` (Nueva - Escritura 1 byte: `0x01` ON, `0x00` OFF).

### Lógica de Control Actual
* **Tracción:** PWM variable (Velocidad de desplazamiento).
* **Rodillo:** PWM variable (Intensidad de limpieza).
* **Bomba:** ON/OFF (Digital).

## 4. Arquitectura de la App Móvil (Flutter)

### Estructura
* `lib/main.dart`: Contiene lógica de escaneo y pantalla de control.
* **Librería:** `flutter_blue_plus`.

### Interfaz de Usuario (Objetivo)
* **Sección Tracción:** Slider velocidad + Botones Dirección (Adelante/Atrás/Parar).
* **Sección Limpieza:**
    * **Rodillo:** Slider velocidad + Botón ON/OFF.
    * **Agua:** Botón "Pulsador" (Hold to spray) o Interruptor para activar la bomba.
* **Sección Estado:** Switch LED y (futuro) estado de sensores.

### Tareas Pendientes en App
* Implementar control de la característica `0xFF03` (Bomba).
* Refactorizar `main.dart` en pantallas separadas.

## 5. Roadmap de Desarrollo

### Fase 1: Hardware & Actuadores (Prioridad Inmediata)
1.  **Bomba:** Implementar control GPIO en firmware y botón en App.
2.  **Pruebas de Carga:** Activar Tracción + Rodillo + Bomba simultáneamente y verificar estabilidad de la fuente de 12V.

### Fase 2: Sensores & Seguridad
1.  **Protección Eléctrica:** Implementar divisores de voltaje (1kΩ/2.2kΩ) o Level Shifters para todos los sensores de 5V.
2.  **Lectura:** Crear tareas en firmware para leer Sensores Hall e IR.
3.  **Lógica de Parada:** Si IR detecta "vacío", cortar PWM de tracción inmediatamente (interrupción o polling de alta prioridad).

### Fase 3: Automatización (Modo Auto)
1.  **Máquina de Estados:**
    * `IDLE` -> `BOMBA_ON` -> `RODILLO_ON` -> `AVANCE` -> `DETECTAR_FIN` -> `PARADA` -> `RETORNO`.

---

### Instrucciones para el Agente de IA (Prompt Context)
*"Actúa como un Ingeniero Senior de Firmware y Desarrollador Flutter. Tienes el contexto del SolarBot v1.1.
1.  **Hardware:** ESP32-S3. Pines Activos: Tracción(2,4,5), Rodillo(6,7,17), **Bomba(15)**, LED(38).
2.  **Stack:** ESP-IDF v5.5 (C) y Flutter (Dart).
3.  **Prioridad:** Seguridad del hardware (niveles de voltaje 3.3V) y robustez del código BLE (Bluedroid).
4.  **Tarea Actual:** Integración del sistema de agua y sensores de seguridad."*