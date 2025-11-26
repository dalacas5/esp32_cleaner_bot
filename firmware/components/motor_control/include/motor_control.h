#ifndef MOTOR_CONTROL_H_
#define MOTOR_CONTROL_H_

#include <stdint.h>

/**
 * @brief Inicializa los pines GPIO y el periférico LEDC para el control de motores.
 */
void motor_control_init(void);

/**
 * @brief Establece la dirección y velocidad de un motor específico.
 * * @param motor_id ID del motor a controlar (0-3).
 * @param direction Dirección del motor (0 = adelante, 1 = atrás).
 * @param speed Velocidad del motor (0-255).
 */
void motor_control_set(uint8_t motor_id, uint8_t direction, uint8_t speed);

#endif /* MOTOR_CONTROL_H_ */