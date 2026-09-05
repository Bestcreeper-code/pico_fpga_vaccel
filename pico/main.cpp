#include "build/qspi_dma.pio.h"
#include "dma_maps/vaccel_map.hpp"
#include "hardware/dma.h"
#include "hardware/irq.h"
#include "hardware/pio.h"
#include "pico/stdio.h"
#include "pico/time.h"
#include "serial_data/serial.h"
#include <hardware/gpio.h>
#include <hardware/timer.h>
#include <pico/types.h>
#include <stdint.h>
#include <stdio.h>

#define SERIAL_IRQ_PIN 13
#define SERIAL_RST_PIN 12
#define SERIAL_DATA_BUS_DIR_PIN 11
#define SERIAL_CLK_PIN 10
#define SERIAL_DATA_BUS_BASE 6
#define SERIAL_DATA_BUS_SIZE 4

int main() {
	stdio_init_all();
	sleep_ms(2000);

	printf("Starting...\n");
	char data_pins[] = {
		SERIAL_DATA_BUS_BASE,
		SERIAL_DATA_BUS_BASE + 1,
		SERIAL_DATA_BUS_BASE + 2,
		SERIAL_DATA_BUS_BASE + 3
	};
	serial_init(
		data_pins,
		SERIAL_CLK_PIN,
		SERIAL_DATA_BUS_DIR_PIN,
		SERIAL_RST_PIN,
		SERIAL_DATA_BUS_SIZE
	);

	char word = 0;
	while (true) {
		int c = getchar_timeout_us(10000000);
		if (c >= '1' && c <= '9') {
			int bit = c - '1';
			uint16_t word = (uint16_t)(1u << bit);
			printf("Sending bit %d: 0x%04X\n", bit, word);
			serial_write_word(word);
		} else if(c == 't') {

			uint8_t led_pattern;
			printf("type hex led pattern: ");
			scanf("%2hhx",&led_pattern);
			printf("Sending led pattern: 0x%02X\n", led_pattern);


			vaccel_command_header cmd = {
				.command_length = sizeof(vaccel_command_header),
				.args = led_pattern,
				.opcode = VACCEL_CMD_SET_STATUS_LED
			};
			serial_write_word(*(uint32_t*)&cmd);
		}

	}
}