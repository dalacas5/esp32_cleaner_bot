#ifndef BLE_SERVER_H_
#define BLE_SERVER_H_

#include "esp_system.h"

/* --- Defines --- */
#define GATTS_TAG "BLE_SERVER"
#define DEVICE_NAME "ESP32_MOTOR_CTRL"


// Definimos un UUID de servicio de 128 bits para nuestro servicio de control de LED
// Lo obtenemos de un generador de UUID online.
// UUID: fb1e400c-54a2-4b2b-a6d1-47a2136b00e0
#define SVC_INST_ID 0
#define GATTS_SERVICE_UUID_A   0x00FF
#define GATTS_CHAR_UUID_A      0xFF01 // Característica para escribir el estado del LED

#define GATTS_CHAR_UUID_MOTOR  0xFF02 // Característica para el motor
#define GATTS_CHAR_UUID_PUMP   0xFF03 // Nueva característica para la bomba

//#define GATTS_DESCR_UUID_A     0x3333
//#define GATTS_NUM_HANDLE_A     4
// #define GATTS_NUM_HANDLE_A     6 // para agregar otra caracteristica al servicio
#define GATTS_NUM_HANDLE_A     12 // Aumentado para soportar la nueva característica y descriptores

/* --- Declaraciones de Funciones Públicas --- */

/**
 * @brief Inicializa y arranca el servidor BLE.
 *
 * Esta función se encarga de configurar toda la pila Bluetooth,
 * registrar los callbacks de GAP y GATTS, y comenzar el advertising.
 */
void ble_server_start(void);


#endif /* BLE_SERVER_H_ */