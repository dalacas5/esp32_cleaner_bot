idf_component_register(SRCS "ble_server.c"
                       INCLUDE_DIRS "include"
                       REQUIRES nvs_flash bt motor_control pump_control led)
