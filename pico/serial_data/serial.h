#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int serial_init(char* data_pins, char clk_pin, char dir_pin, char rst_pin, uint8_t pin_amount);

int serial_write_word(uint32_t word);
uint32_t serial_read_word();

#ifdef __cplusplus
}
#endif