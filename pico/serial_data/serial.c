#include "serial.h"
#include <hardware/gpio.h>
#include <pico/time.h>
#include <pico/types.h>


static char* serial_pins = NULL;
static uint8_t serial_pin_amount = -1;
static char serial_clk_pin = -1;
static char serial_dir_pin = -1;
static char serial_rst_pin = -1;

static bool pins_dir_out = 1;

int serial_init(char* data_pins, char clk_pin, char dir_pin, char rst_pin, uint8_t pin_amount) {
    assert(data_pins != NULL);
    assert(pin_amount > 0);
    assert(clk_pin >= 0);
    assert(dir_pin >= 0);
    assert(rst_pin >= 0);
    assert(pin_amount == 4);

    serial_pins = data_pins;
    serial_pin_amount = pin_amount;
    serial_clk_pin = clk_pin;
    serial_dir_pin = dir_pin;

    for(int i = 0; i < pin_amount; i++) {
        gpio_init(data_pins[i]);
        gpio_set_dir(data_pins[i], GPIO_OUT);   
    }

    gpio_init(clk_pin);
    gpio_set_dir(clk_pin, GPIO_OUT);

    gpio_init(dir_pin);
    gpio_set_dir(dir_pin, GPIO_OUT);
    gpio_put(dir_pin, 1); //sets the fpga in rx mode

    //active low rst
    gpio_put(rst_pin, 0);
    sleep_ms(10);
    gpio_put(rst_pin, 1); 

    return 0;
}

int serial_write_word(uint32_t word) {
    gpio_put(serial_dir_pin, 1); // rx mode on FPGA

    int chunks = 32 / serial_pin_amount; // expects serial_pin_amount == 4
    for (int c = 0; c < chunks; c++) {
        int shift = 32 - (c + 1) * serial_pin_amount;
        for (int p = 0; p < serial_pin_amount; p++) {
            int bit = (word >> (shift + p)) & 0x1;   // p=0 is now LSB of nibble
            gpio_put(serial_pins[p], bit);
        }
        gpio_put(serial_clk_pin, 1);
        gpio_put(serial_clk_pin, 0);
    }
    return 0;
}

uint32_t serial_read_word() {
    if (pins_dir_out) {
        for(int i = 0; i < serial_pin_amount; i++) {
            gpio_set_dir(serial_pins[i], GPIO_IN);
        }
    }

    gpio_put(serial_dir_pin, 0); // tx mode on FPGA
    uint32_t word = 0;

    int chunks = 32 / serial_pin_amount;
    for (int c = 0; c < chunks; c++) {
        gpio_put(serial_clk_pin, 1);
        int shift = 32 - (c + 1) * serial_pin_amount;
        for (int p = 0; p < serial_pin_amount; p++) {
            int bit = gpio_get(serial_pins[p]);
            word |= (bit << (shift + serial_pin_amount - 1 - p));
        }
        gpio_put(serial_clk_pin, 0);
    }
    return word;
}