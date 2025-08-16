#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// FreeRTOS
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"

// ESP-IDF
#include "esp_system.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_bt.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_bt_main.h"
#include "esp_gatt_common_api.h"

// Control del led
#include "led.h"

// Control de los motores
#include "motor_control.h"

// Nuestro header
#include "ble_server.h"

static uint16_t motor_char_handle;

// descriptores de nombre de las caracteristicas del servicio
static const char *led_descr_str = "Control del LED";
static const char *motor_descr_str = "Control de Motores";


#define PROFILE_NUM 1
#define PROFILE_A_APP_ID 0


struct gatts_profile_inst {
    esp_gatts_cb_t gatts_cb;
    uint16_t gatts_if;
    uint16_t app_id;
    uint16_t conn_id;
    uint16_t service_handle;
    esp_gatt_srvc_id_t service_id;
    uint16_t char_handle;
    esp_bt_uuid_t char_uuid;
    esp_gatt_perm_t perm;
    esp_gatt_char_prop_t property;
    uint16_t descr_handle;
    esp_bt_uuid_t descr_uuid;
};

// Declaraciones de funciones estáticas (manejadores de eventos)
static void gatts_profile_a_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param);
static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param);

// Tabla de perfiles GATT, solo tenemos uno
static struct gatts_profile_inst gl_profile_tab[PROFILE_NUM] = {
    [PROFILE_A_APP_ID] = {
        .gatts_cb = gatts_profile_a_event_handler,
        .gatts_if = ESP_GATT_IF_NONE,
    },
};

// Configuración de Advertising
static esp_ble_adv_params_t adv_params = {
    .adv_int_min        = 0x20,
    .adv_int_max        = 0x40,
    .adv_type           = ADV_TYPE_IND,
    .own_addr_type      = BLE_ADDR_TYPE_PUBLIC,
    .channel_map        = ADV_CHNL_ALL,
    .adv_filter_policy  = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

// Datos de Advertising
static esp_ble_adv_data_t adv_data = {
    .set_scan_rsp       = false,
    .include_name       = true,
    .include_txpower    = true,
    .min_interval       = 0x0006, // Slave conn. min interval, Time = min_interval * 1.25 msec
    .max_interval       = 0x0010, // Slave conn. max interval, Time = max_interval * 1.25 msec
    .appearance         = 0x00,
    .manufacturer_len   = 0,
    .p_manufacturer_data = NULL,
    .service_data_len   = 0,
    .p_service_data     = NULL,
    .service_uuid_len   = 0,      // Se configurará en el evento de registro
    .p_service_uuid     = NULL,
    .flag               = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
};

static uint8_t adv_config_done = 0;
#define adv_config_flag      (1 << 0)
#define scan_rsp_config_flag (1 << 1)

// --- FUNCIONES DE CONFIGURACIÓN Y MANEJO DE EVENTOS ---

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    switch (event) {
    case ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT:
        adv_config_done &= (~adv_config_flag);
        if (adv_config_done == 0){
            esp_ble_gap_start_advertising(&adv_params);
        }
        break;
    case ESP_GAP_BLE_SCAN_RSP_DATA_SET_COMPLETE_EVT:
        adv_config_done &= (~scan_rsp_config_flag);
        if (adv_config_done == 0){
            esp_ble_gap_start_advertising(&adv_params);
        }
        break;
    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        if (param->adv_start_cmpl.status != ESP_BT_STATUS_SUCCESS) {
            ESP_LOGE(GATTS_TAG, "Error al iniciar advertising");
        } else {
            ESP_LOGI(GATTS_TAG, "Advertising iniciado correctamente");
        }
        break;
    case ESP_GAP_BLE_ADV_STOP_COMPLETE_EVT:
        if (param->adv_stop_cmpl.status != ESP_BT_STATUS_SUCCESS) {
            ESP_LOGE(GATTS_TAG, "Error al detener advertising");
        } else {
            ESP_LOGI(GATTS_TAG, "Advertising detenido correctamente");
        }
        break;
    case ESP_GAP_BLE_UPDATE_CONN_PARAMS_EVT:
         ESP_LOGI(GATTS_TAG, "update connection params status = %d, min_int = %d, max_int = %d,conn_int = %d,latency = %d, timeout = %d",
                  param->update_conn_params.status,
                  param->update_conn_params.min_int,
                  param->update_conn_params.max_int,
                  param->update_conn_params.conn_int,
                  param->update_conn_params.latency,
                  param->update_conn_params.timeout);
        break;
    default:
        break;
    }
}


static void gatts_profile_a_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param) {
    switch (event) {
    // ... los casos REG_EVT y CREATE_EVT no cambian ...
    case ESP_GATTS_REG_EVT:
        esp_ble_gap_set_device_name(DEVICE_NAME);
        esp_ble_gap_config_adv_data(&adv_data);
        gl_profile_tab[PROFILE_A_APP_ID].service_id.is_primary = true;
        gl_profile_tab[PROFILE_A_APP_ID].service_id.id.inst_id = 0x00;
        gl_profile_tab[PROFILE_A_APP_ID].service_id.id.uuid.len = ESP_UUID_LEN_16;
        gl_profile_tab[PROFILE_A_APP_ID].service_id.id.uuid.uuid.uuid16 = GATTS_SERVICE_UUID_A;
        esp_ble_gatts_create_service(gatts_if, &gl_profile_tab[PROFILE_A_APP_ID].service_id, GATTS_NUM_HANDLE_A);
        break;

    case ESP_GATTS_CREATE_EVT:
        ESP_LOGI(GATTS_TAG, "Servicio creado, añadiendo 1ra característica (LED)...");
        gl_profile_tab[PROFILE_A_APP_ID].service_handle = param->create.service_handle;
        esp_ble_gatts_start_service(gl_profile_tab[PROFILE_A_APP_ID].service_handle);
        esp_ble_gatts_add_char(gl_profile_tab[PROFILE_A_APP_ID].service_handle,
                               &(esp_bt_uuid_t){.len = ESP_UUID_LEN_16, .uuid = {.uuid16 = GATTS_CHAR_UUID_A}},
                               ESP_GATT_PERM_WRITE, ESP_GATT_CHAR_PROP_BIT_WRITE,
                               NULL, NULL);
        break;

    case ESP_GATTS_ADD_CHAR_EVT: {
        uint16_t char_uuid = param->add_char.char_uuid.uuid.uuid16;
        ESP_LOGI(GATTS_TAG, "Característica añadida (uuid 0x%04X), añadiendo su descriptor...", char_uuid);

        // Preparamos el control para la respuesta automática
        esp_attr_control_t ctl = {.auto_rsp = ESP_GATT_AUTO_RSP};

        if (char_uuid == GATTS_CHAR_UUID_A) {
            gl_profile_tab[PROFILE_A_APP_ID].char_handle = param->add_char.attr_handle;
            esp_ble_gatts_add_char_descr(gl_profile_tab[PROFILE_A_APP_ID].service_handle,
                                         &(esp_bt_uuid_t){.len = ESP_UUID_LEN_16, .uuid = {.uuid16 = ESP_GATT_UUID_CHAR_DESCRIPTION}},
                                         ESP_GATT_PERM_READ,
                                         (esp_attr_value_t *)&(esp_attr_value_t){.attr_max_len = 128, .attr_len = strlen(led_descr_str), .attr_value = (uint8_t *)led_descr_str},
                                         // CORRECCIÓN: Usar respuesta automática en lugar de NULL
                                         &ctl);
        } else if (char_uuid == GATTS_CHAR_UUID_MOTOR) {
            motor_char_handle = param->add_char.attr_handle;
            esp_ble_gatts_add_char_descr(gl_profile_tab[PROFILE_A_APP_ID].service_handle,
                                         &(esp_bt_uuid_t){.len = ESP_UUID_LEN_16, .uuid = {.uuid16 = ESP_GATT_UUID_CHAR_DESCRIPTION}},
                                         ESP_GATT_PERM_READ,
                                         (esp_attr_value_t *)&(esp_attr_value_t){.attr_max_len = 128, .attr_len = strlen(motor_descr_str), .attr_value = (uint8_t *)motor_descr_str},
                                         // CORRECCIÓN: Usar respuesta automática en lugar de NULL
                                         &ctl);
        }
        break;
    }

    case ESP_GATTS_ADD_CHAR_DESCR_EVT: {
        // CORRECCIÓN 2: Nombre del parámetro del evento
        uint16_t descr_uuid = param->add_char_descr.descr_uuid.uuid.uuid16;
        if (descr_uuid == ESP_GATT_UUID_CHAR_DESCRIPTION) {
             if (motor_char_handle == 0) {
                 ESP_LOGI(GATTS_TAG, "Descriptor del LED añadido. Añadiendo característica del Motor...");
                 esp_ble_gatts_add_char(gl_profile_tab[PROFILE_A_APP_ID].service_handle,
                                        &(esp_bt_uuid_t){.len = ESP_UUID_LEN_16, .uuid = {.uuid16 = GATTS_CHAR_UUID_MOTOR}},
                                        ESP_GATT_PERM_WRITE, ESP_GATT_CHAR_PROP_BIT_WRITE,
                                        NULL, NULL);
             } else {
                 ESP_LOGI(GATTS_TAG, "Descriptor del Motor añadido. Creación finalizada.");
             }
        }
        break;
    }

    // ... los casos WRITE, CONNECT, etc. no cambian ...
    case ESP_GATTS_WRITE_EVT:
        if (param->write.handle == gl_profile_tab[PROFILE_A_APP_ID].char_handle && param->write.len > 0) {
            led_control_set_state(param->write.value[0] == 0x01);
        } else if (param->write.handle == motor_char_handle && param->write.len >= 3) {
            uint8_t motor_id = param->write.value[0];
            uint8_t direction = param->write.value[1];
            uint8_t speed = param->write.value[2];
            motor_control_set(motor_id, direction, speed);
        }
        if (param->write.need_rsp) {
            esp_ble_gatts_send_response(gatts_if, param->write.conn_id, param->write.trans_id, ESP_GATT_OK, NULL);
        }
        break;
    case ESP_GATTS_CONNECT_EVT:
         gl_profile_tab[PROFILE_A_APP_ID].conn_id = param->connect.conn_id;
         break;
    case ESP_GATTS_DISCONNECT_EVT:
         esp_ble_gap_start_advertising(&adv_params);
         break;
    default:
        break;
    }
}


static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param)
{
    /* If event is register event, store the gatts_if for each profile */
    if (event == ESP_GATTS_REG_EVT) {
        if (param->reg.status == ESP_GATT_OK) {
            gl_profile_tab[param->reg.app_id].gatts_if = gatts_if;
        } else {
            ESP_LOGE(GATTS_TAG, "Reg app failed, app_id %04x, status %d",
                    param->reg.app_id,
                    param->reg.status);
            return;
        }
    }

    /* Call the corresponding profile's callback function */
    do {
        int idx;
        for (idx = 0; idx < PROFILE_NUM; idx++) {
            if (gatts_if == ESP_GATT_IF_NONE || gatts_if == gl_profile_tab[idx].gatts_if) {
                if (gl_profile_tab[idx].gatts_cb) {
                    gl_profile_tab[idx].gatts_cb(event, gatts_if, param);
                }
            }
        }
    } while (0);
}


void ble_server_start(void)
{
    esp_err_t ret;

    // Inicializacion del led
    led_control_init();

    // Inicializacion de los motores
    motor_control_init();
    

    // Inicializar el controlador Bluetooth
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret) {
        ESP_LOGE(GATTS_TAG, "%s initialize controller failed: %s", __func__, esp_err_to_name(ret));
        return;
    }

    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret) {
        ESP_LOGE(GATTS_TAG, "%s enable controller failed: %s", __func__, esp_err_to_name(ret));
        return;
    }

    // Inicializar el stack Bluedroid
    ret = esp_bluedroid_init();
    if (ret) {
        ESP_LOGE(GATTS_TAG, "%s init bluetooth failed: %s", __func__, esp_err_to_name(ret));
        return;
    }
    ret = esp_bluedroid_enable();
    if (ret) {
        ESP_LOGE(GATTS_TAG, "%s enable bluetooth failed: %s", __func__, esp_err_to_name(ret));
        return;
    }

    // Registrar los manejadores de eventos
    ret = esp_ble_gatts_register_callback(gatts_event_handler);
    if (ret){
        ESP_LOGE(GATTS_TAG, "gatts register error, error code = %x", ret);
        return;
    }
    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret){
        ESP_LOGE(GATTS_TAG, "gap register error, error code = %x", ret);
        return;
    }
    
    // Registrar nuestra aplicación/perfil
    ret = esp_ble_gatts_app_register(PROFILE_A_APP_ID);
    if (ret){
        ESP_LOGE(GATTS_TAG, "gatts app register error, error code = %x", ret);
        return;
    }
    
    // Configurar MTU
    esp_err_t local_mtu_ret = esp_ble_gatt_set_local_mtu(500);
    if (local_mtu_ret){
        ESP_LOGE(GATTS_TAG, "set local  MTU failed, error code = %x", local_mtu_ret);
    }
}