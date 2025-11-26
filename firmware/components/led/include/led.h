#ifndef LED_H_
#define LED_H_

#include <stdbool.h>

/**
 * @brief Inicializa el driver del LED direccionable.
 * * Debe ser llamada una vez al inicio del programa.
 */
void led_control_init(void);

/**
 * @brief Establece el estado del LED.
 * * @param on true para encender el LED (blanco), false para apagarlo.
 */
void led_control_set_state(bool on);

#endif /* LED_H_ */