#include <stdio.h>
#include "esp_log.h"
#include "nvs_flash.h"

#include "ble_server.h"

void app_main(void)
{
    esp_err_t ret;

    // --- 1. Inicializar NVS ---
    // El stack Bluetooth requiere que NVS (Non-Volatile Storage) esté inicializado.
    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
      ESP_ERROR_CHECK(nvs_flash_erase());
      ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // --- 2. Iniciar nuestro servidor BLE ---
    // Esta única llamada pone en marcha todo el proceso que definimos en ble_server.c
    ble_server_start();

    ESP_LOGI("MAIN", "Inicialización completada.");
}