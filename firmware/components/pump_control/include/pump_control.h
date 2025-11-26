#ifndef PUMP_CONTROL_H_
#define PUMP_CONTROL_H_

#include <stdint.h>
#include <stdbool.h>

/**
 * @brief Inicializa el control de la bomba.
 * Configura el GPIO como salida.
 */
void pump_control_init(void);

/**
 * @brief Enciende o apaga la bomba.
 * 
 * @param enable true para encender, false para apagar.
 */
void pump_control_set(bool enable);

#endif /* PUMP_CONTROL_H_ */
