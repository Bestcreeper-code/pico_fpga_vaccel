#pragma once

#include <stdint.h>

int serial_init(char* data_pins, char clk_pin, uint8_t pin_amount);

int serial_write_word(uint32_t word);
uint32_t serial_read_word();