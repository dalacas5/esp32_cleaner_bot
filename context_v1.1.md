# SolarBot v1.1 - Contexto del Proyecto

## 1. Estado del Proyecto

**Versión Actual:** v1.1  
**Estado:** ✅ **Fase de Pruebas y Refinamiento**  
**Última Actualización:** Noviembre 2025

### Funcionalidades Completadas
- ✅ Control BLE bidireccional (ESP32 ↔ App)
- ✅ Sistema de tracción con control variable
- ✅ Sistema de limpieza (rodillo) con velocidad y dirección configurables
- ✅ Bomba de agua con control ON/OFF
- ✅ Interfaz móvil moderna con controles avanzados
- ✅ Arquitectura modular (Firmware y App refactorizados)

### Pendiente
- ⏳ Integración de sensores (Encoders, Hall, IR)
- ⏳ Modo automático con máquina de estados
- ⏳ Monitoreo de batería real

## 2. Hardware

### Actuadores Principales

1. **Sistema de Tracción (Motor 0 - Lógico):**
   - **Función:** Desplazamiento del robot (adelante/atrás).
   - **Implementación:** 2x Motores DC 12V en paralelo.
   - **Mecánica:** Transmisión piñón-cadena.
   - **Electrónica:** 2x Drivers L298N en paralelo.
   - **Pines ESP32-S3:** PWM (GPIO 2), IN1 (GPIO 4), IN2 (GPIO 5).
   - **Canal LEDC:** 0

2. **Sistema de Limpieza (Motor 1 - Lógico):**
   - **Función:** Rotación del rodillo de limpieza.
   - **Implementación:** 1x Motor DC 12V con acople directo.
   - **Electrónica:** 1x Driver L298N.
   - **Pines ESP32-S3:** PWM (GPIO 6), IN1 (GPIO 7), IN2 (GPIO 17).
   - **Canal LEDC:** 1
   - **Control:** Velocidad variable (0-100%) + Dirección (Horario/Antihorario)

3. **Sistema de Humidificación:**
   - **Función:** Rociar agua/líquido sobre superficies.
   - **Hardware:** Bomba de agua 12 VDC + 2 Aspersores.
   - **Control:** Módulo Relé 3.3V / MOSFET.
   - **Pin ESP32-S3:** **GPIO 15** (Salida Digital).

4. **Feedback Visual:**
   - **LED RGB:** WS2812 en GPIO 38.

### Sensores (Pendientes)
- **Encoders:** Medición de distancia en eje de tracción.
- **Hall:** Detección de inicio/fin de fila.
- **IR 5V:** Detección de vacío/vuelco *(Requiere level shifter)*.

## 3. Arquitectura del Firmware (ESP32-S3)

### Estructura de Componentes
```
firmware/
├── components/
│   ├── ble_server/       # Servidor BLE GATT (Bluedroid)
│   ├── motor_control/    # Control PWM (LEDC) para motores
│   ├── pump_control/     # Control GPIO para bomba
│   └── led/              # Control WS2812
└── main/
    └── main.c            # Inicialización y orquestación
```

### Especificaciones BLE (GATT Server)
- **Nombre Dispositivo:** `ESP32_MOTOR_CTRL`
- **Servicio Principal:** `0x00FF`
- **Características:**
  1. **LED:** `0xFF01` (Escritura 1 byte: `0x01`/`0x00`)
  2. **Motores:** `0xFF02` (Escritura 3 bytes: `[ID, Dir, Vel]`)
     - *ID 0:* Tracción
     - *ID 1:* Rodillo
  3. **Bomba:** `0xFF03` (Escritura 1 byte: `0x01` ON / `0x00` OFF)

### Lógica de Control
- **Tracción:** PWM variable (0-255) con dirección (0=Adelante, 1=Atrás)
- **Rodillo:** PWM variable (0-255) + Dirección (0=Horario, 1=Antihorario)
- **Bomba:** Digital ON/OFF
- **Throttling:** Comandos limitados a 10/seg para evitar saturación BLE

## 4. Arquitectura de la App Móvil (Flutter)

### Estructura Modular
```
mobile_app/lib/
├── screens/
│   ├── scan_screen.dart       # Escaneo BLE
│   └── device_screen.dart     # Control principal
├── widgets/
│   ├── throttle_widget.dart   # Deslizador vertical de tracción
│   └── motor_control_card.dart # (Legacy, no usado)
└── main.dart                  # MaterialApp
```

### Interfaz de Usuario

#### Dashboard
- **Estado:** Conectado/Desconectado
- **Velocidad:** Porcentaje actual (0-100%)
- **Modo:** Manual/Auto (placeholder)

#### Controles

**Tracción (Throttle Vertical)**
- Deslizador con centro=Parado
- Arriba → Avanza (0-100%)
- Abajo → Retrocede (0-100%)
- Indicador de % integrado

**Rodillo (Tap/Long Press)**
- **Tap corto:** ON/OFF rápido (usa configuración guardada)
- **Tap largo:** Abre Bottom Sheet con:
  - Slider de velocidad (0-100%)
  - Botones de dirección (⟲ Horario / ⟳ Antihorario)
  - Aplicación en tiempo real

**Bomba**
- Toggle ON/OFF simple

**LED**
- Toggle ON/OFF para feedback visual

### Optimizaciones
- **BLE Throttling:** Máximo 10 comandos/segundo con Timer periódico
- **UI Reactiva:** Actualización en tiempo real sin lag
- **Bottom Sheet:** Patrón moderno para configuraciones avanzadas

## 5. Roadmap de Desarrollo

### ✅ Fase 1: Actuadores Básicos (Completada)
- Motores de tracción y rodillo
- Bomba de agua
- Control BLE funcional

### ✅ Fase 2: Refactorización (Completada)
- Firmware: Estructura de componentes ESP-IDF
- App: Separación de screens/widgets
- Código limpio y mantenible

### ✅ Fase 3: UI Avanzada (Completada)
- Throttle control intuitivo
- Controles avanzados del rodillo
- Dashboard informativo
- Optimización BLE

### ⏳ Fase 4: Sensórica (En Planificación)
1. **Encoders:** Odometría básica
2. **Hall:** Referencia de posición
3. **IR:** Seguridad anti-caída
4. **Level Shifters:** Protección 5V→3.3V

### ⏳ Fase 5: Automatización (Futuro)
1. **Máquina de Estados:**
   - `IDLE` → `PREPARAR` → `LIMPIAR` → `AVANZAR` → `DETECTAR_FIN` → `RETORNAR`
2. **Navegación autónoma** basada en sensores
3. **Monitoreo de batería** en tiempo real

---

## 6. Notas Técnicas

### Seguridad Eléctrica
- ⚠️ Sensores IR son de 5V → **Usar divisor de voltaje (1kΩ/2.2kΩ)** o level shifter
- ✅ Todos los GPIOs del ESP32-S3 operan a **3.3V máximo**

### BLE Best Practices
- ✅ Throttling implementado para evitar spam
- ✅ UUIDs alineados entre firmware y app
- ✅ Handles almacenados globalmente para eventos confiables

### Consideraciones de Diseño
- **Rodillo bidireccional:** Permite limpieza en ambos sentidos de avance
- **Bomba controlada:** Evita desperdicio de agua/líquido
- **UI intuitiva:** Tap rápido para uso simple, long-press para configuración avanzada

---

## 7. Instrucciones para Desarrollo Futuro

### Para Agentes de IA
*"Actúa como Ingeniero Senior Embedded y Desarrollador Flutter con experiencia en:*
1. **Hardware:** ESP32-S3, Drivers L298N, sensores 3.3V/5V.
2. **Stack:** ESP-IDF v5.5 (C), Flutter (Dart), BLE Bluedroid.
3. **Prioridades:** Seguridad eléctrica (niveles lógicos), robustez BLE, UX intuitiva.
4. **Código:** Modular, documentado, siguiendo best practices de ESP-IDF y Flutter.
5. **Testing:** Validación manual con hardware real antes de integrar sensores críticos."*

### Próximos Pasos Sugeridos
1. Implementar lectura de encoders para odometría
2. Agregar pantalla "Auto Mode" con visualización de sensores
3. Implementar máquina de estados básica
4. Añadir logging BLE para debugging remoto