#include "motor_control.h"
#include "driver/ledc.h"
#include "driver/gpio.h"
#include "esp_log.h"

// --- Constantes y Estructuras Privadas ---
static const char *TAG = "MOTOR_CONTROL";

// Estructura para definir la configuración de un solo motor
typedef struct {
    int pwm_gpio;
    int in1_gpio;
    int in2_gpio;
    ledc_channel_t ledc_channel;
} motor_config_t;

// Array con la configuración de los 4 motores
// ¡IMPORTANTE! Debes ajustar estos pines a tu hardware real.
static const motor_config_t motor_configs[4] = {
    { .pwm_gpio = GPIO_NUM_2,  .in1_gpio = GPIO_NUM_4,  .in2_gpio = GPIO_NUM_5,  .ledc_channel = LEDC_CHANNEL_0 }, // Motor 0
    { .pwm_gpio = GPIO_NUM_6,  .in1_gpio = GPIO_NUM_7,  .in2_gpio = GPIO_NUM_17,  .ledc_channel = LEDC_CHANNEL_1 }, // Motor 1
    // { .pwm_gpio = 7,  .in1_gpio = 8,  .in2_gpio = 9,  .ledc_channel = LEDC_CHANNEL_2 }, // Motor 2
    // { .pwm_gpio = 10, .in1_gpio = 11, .in2_gpio = 12, .ledc_channel = LEDC_CHANNEL_3 }  // Motor 3
};

#define NUM_MOTORS (sizeof(motor_configs) / sizeof(motor_config_t))

// Configuración del periférico LEDC (PWM) - Común para todos los motores
#define LEDC_TIMER              LEDC_TIMER_0
#define LEDC_MODE               LEDC_LOW_SPEED_MODE
#define LEDC_DUTY_RES           LEDC_TIMER_10_BIT // Resolución de 10 bits (0-1023)
#define LEDC_FREQUENCY          (5000) // Frecuencia de 5 kHz

// --- Implementación de Funciones ---

void motor_control_init(void) {
    ESP_LOGI(TAG, "Inicializando control para %d motores...", NUM_MOTORS);

    // 1. Configurar el Timer de LEDC (solo se hace una vez)
    ledc_timer_config_t ledc_timer = {
        .speed_mode       = LEDC_MODE,
        .timer_num        = LEDC_TIMER,
        .duty_resolution  = LEDC_DUTY_RES,
        .freq_hz          = LEDC_FREQUENCY,
        .clk_cfg          = LEDC_AUTO_CLK
    };
    ESP_ERROR_CHECK(ledc_timer_config(&ledc_timer));

    // 2. Iterar sobre cada motor para configurar sus pines y canal LEDC
    for (int i = 0; i < NUM_MOTORS; i++) {
        // Configurar pines de dirección
        gpio_reset_pin(motor_configs[i].in1_gpio);
        gpio_reset_pin(motor_configs[i].in2_gpio);
        gpio_set_direction(motor_configs[i].in1_gpio, GPIO_MODE_OUTPUT);
        gpio_set_direction(motor_configs[i].in2_gpio, GPIO_MODE_OUTPUT);

        // Configurar el Canal de LEDC para este motor
        ledc_channel_config_t ledc_channel = {
            .speed_mode     = LEDC_MODE,
            .channel        = motor_configs[i].ledc_channel,
            .timer_sel      = LEDC_TIMER,
            .intr_type      = LEDC_INTR_DISABLE,
            .gpio_num       = motor_configs[i].pwm_gpio,
            .duty           = 0, // Empezar con el motor parado
            .hpoint         = 0
        };
        ESP_ERROR_CHECK(ledc_channel_config(&ledc_channel));
    }
}

void motor_control_set(uint8_t motor_id, uint8_t direction, uint8_t speed) {
    // Comprobar que el ID del motor es válido
    if (motor_id >= NUM_MOTORS) {
        ESP_LOGE(TAG, "ID de motor inválido: %d", motor_id);
        return;
    }

    // Apuntar a la configuración del motor solicitado
    const motor_config_t* motor = &motor_configs[motor_id];

    // Lógica de dirección
    if (direction == 0) { // Adelante
        gpio_set_level(motor->in1_gpio, 1);
        gpio_set_level(motor->in2_gpio, 0);
    } else { // Atrás
        gpio_set_level(motor->in1_gpio, 0);
        gpio_set_level(motor->in2_gpio, 1);
    }

    // Lógica de velocidad
    uint32_t duty_cycle = (speed * 1023) / 255;
    
    ESP_LOGI(TAG, "Motor %d: Dir=%d, Vel=%d -> Duty=%lu", motor_id, direction, speed, duty_cycle);

    ESP_ERROR_CHECK(ledc_set_duty(LEDC_MODE, motor->ledc_channel, duty_cycle));
    ESP_ERROR_CHECK(ledc_update_duty(LEDC_MODE, motor->ledc_channel));
}