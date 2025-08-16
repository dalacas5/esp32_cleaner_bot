#include "led.h"
#include "led_strip.h"
#include "esp_log.h"

// --- Constantes y Variables Privadas del Módulo ---
static const char *TAG = "LED_CONTROL";
#define LED_GPIO 38

static led_strip_handle_t led_strip;

// --- Implementación de Funciones Públicas ---

void led_control_init(void)
{
    ESP_LOGI(TAG, "Inicializando el LED direccionable (WS2812)...");

    led_strip_config_t strip_config = {
        .strip_gpio_num = LED_GPIO,
        .max_leds = 1,
    };
    led_strip_rmt_config_t rmt_config = {
        .resolution_hz = 10 * 1000 * 1000, // 10MHz
    };
    ESP_ERROR_CHECK(led_strip_new_rmt_device(&strip_config, &rmt_config, &led_strip));
    
    // Apagar el LED al inicio
    led_strip_clear(led_strip);
}

void led_control_set_state(bool on)
{
    if (on) {
        // Encender el LED en blanco (R, G, B con brillo moderado)
        ESP_LOGI(TAG, "Encendiendo LED");
        led_strip_set_pixel(led_strip, 0, 32, 32, 32);
        led_strip_refresh(led_strip);
    } else {
        // Apagar el LED
        ESP_LOGI(TAG, "Apagando LED");
        led_strip_clear(led_strip);
    }
}