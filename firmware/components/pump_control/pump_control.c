#include "pump_control.h"
#include "driver/gpio.h"
#include "esp_log.h"

static const char *TAG = "PUMP_CONTROL";

// Definición del PIN de la bomba (GPIO 15 según documentación)
#define PUMP_GPIO GPIO_NUM_15

void pump_control_init(void) {
    ESP_LOGI(TAG, "Inicializando control de bomba en GPIO %d", PUMP_GPIO);
    
    // Configurar el GPIO como salida
    gpio_reset_pin(PUMP_GPIO);
    gpio_set_direction(PUMP_GPIO, GPIO_MODE_OUTPUT);
    gpio_set_level(PUMP_GPIO, 0); // Asegurar que empieza apagada
}

void pump_control_set(bool enable) {
    ESP_LOGI(TAG, "Bomba %s", enable ? "ENCENDIDA" : "APAGADA");
    gpio_set_level(PUMP_GPIO, enable ? 1 : 0);
}
