#include "serial.h"
#include <hardware/gpio.h>
#include <pico/types.h>


static char* serial_pins = NULL;
static uint8_t serial_pin_amount = -1;
static char serial_clk_pin = -1;

int serial_init(char* data_pins, char clk_pin, uint8_t pin_amount) {
    assert(data_pins != NULL);
    assert(pin_amount > 0);
    assert(clk_pin >= 0);

    serial_pins = data_pins;
    serial_pin_amount = pin_amount;
    serial_clk_pin = clk_pin;

    for(int i = 0; i < pin_amount; i++) {
        gpio_init(data_pins[i]);
        gpio_set_dir(data_pins[i], GPIO_OUT);   
    }
    gpio_init(clk_pin);
    gpio_set_dir(clk_pin, GPIO_OUT);

    return 0;
}

int serial_write_word(uint32_t word) {
    for(int i = 0; i < 32; i++) {
        int bit = (word >> (31 - i)) & 0x1;
        gpio_put(serial_pins[i%serial_pin_amount], bit);
        gpio_put(serial_clk_pin, 1);
        gpio_put(serial_clk_pin, 0);
    }

    return 0;
}

uint32_t serial_read_word() {
    uint32_t word = 0;
    for(int i = 0; i < 32; i++) {
        gpio_put(serial_clk_pin, 1);
        int bit = gpio_get(serial_pins[i%serial_pin_amount]);
        word |= (bit << (31 - i));
        gpio_put(serial_clk_pin, 0);
    }

    return word;
}