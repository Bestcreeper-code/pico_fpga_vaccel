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
		}else if (c == 'c') {
			// 16x16 Grid Configuration (256 pixels total)
			const int WIDTH = 16;
			const int HEIGHT = 16;
			uint16_t color = 0xFFFF;
		
			// Paddle height scaled for 16x16 grid
			const int paddle_h = 3;
			int paddle1_y = HEIGHT / 2 - paddle_h / 2;
			int paddle2_y = HEIGHT / 2 - paddle_h / 2;
		
			float ball_x = WIDTH / 2;
			float ball_y = HEIGHT / 2;
			
			// Ball velocity set to 1/3 of previous speed
			float ball_dir_x = 0.133f;
			float ball_dir_y = 0.083f;
		
			// Helper macro to send a pixel command to the bus
			#define DRAW_PIXEL(addr, col) do { \
				vaccel_command_header cmd = { \
					.command_length = (col), \
					.args = (uint8_t)(addr), \
					.opcode = VACCEL_CMD_WRITE_LOHALF_BYTEADDR_DBUS \
				}; \
				serial_write_word(*(uint32_t *)&cmd); \
			} while(0)
		
			printf("Starting 16x16 Slow Ball Pong! Controls: W/S (P1), I/K (P2), Q to quit.\n");
		
			absolute_time_t last_frame_time = get_absolute_time();
		
			while (1) {
				// 1. Flush and process all pending non-blocking inputs
				int input;
				while ((input = getchar_timeout_us(0)) != PICO_ERROR_TIMEOUT) {
					char in_c = (char)input;
					if (in_c == 'q' || in_c == 'Q') {
						goto exit_pong; // Exit game loop
					}
					// Player 1 controls (Left)
					if ((in_c == 'w' || in_c == 'W') && paddle1_y > 0) paddle1_y--;
					if ((in_c == 's' || in_c == 'S') && paddle1_y < HEIGHT - paddle_h) paddle1_y++;
					// Player 2 controls (Right)
					if ((in_c == 'i' || in_c == 'I') && paddle2_y > 0) paddle2_y--;
					if ((in_c == 'k' || in_c == 'K') && paddle2_y < HEIGHT - paddle_h) paddle2_y++;
				}
		
				// 2. Frame timing (~30 FPS / 33ms update rate)
				absolute_time_t now = get_absolute_time();
				if (absolute_time_diff_us(last_frame_time, now) >= 33000) {
					last_frame_time = now;
		
					// Clear Screen (Overwrite all 256 pixels with 0x00)
					for (int i = 0; i < WIDTH * HEIGHT; i++) {
						DRAW_PIXEL(i, 0x00);
					}
		
					// Move Ball (3x Slower)
					ball_x += ball_dir_x;
					ball_y += ball_dir_y;
		
					// Bounce off top and bottom boundaries
					if (ball_y <= 0 || ball_y >= HEIGHT - 1) {
						ball_dir_y = -ball_dir_y;
					}
		
					// Left Paddle Collision
					if (ball_x <= 1 && ball_y >= paddle1_y && ball_y < paddle1_y + paddle_h) {
						ball_dir_x = -ball_dir_x;
						ball_x = 1;
					}
		
					// Right Paddle Collision
					if (ball_x >= WIDTH - 2 && ball_y >= paddle2_y && ball_y < paddle2_y + paddle_h) {
						ball_dir_x = -ball_dir_x;
						ball_x = WIDTH - 2;
					}
		
					// Reset ball position on out-of-bounds score
					if (ball_x < 0 || ball_x >= WIDTH) {
						ball_x = WIDTH / 2;
						ball_y = HEIGHT / 2;
						ball_dir_x = -ball_dir_x;
					}
		
					// Draw Left Paddle (x = 0)
					for (int y = 0; y < paddle_h; y++) {
						int addr = (paddle1_y + y) * WIDTH + 0;
						DRAW_PIXEL(addr, color);
					}
		
					// Draw Right Paddle (x = 15)
					for (int y = 0; y < paddle_h; y++) {
						int addr = (paddle2_y + y) * WIDTH + (WIDTH - 1);
						DRAW_PIXEL(addr, color);
					}
		
					// Draw Ball
					int ball_addr = ((int)ball_y) * WIDTH + ((int)ball_x);
					DRAW_PIXEL(ball_addr, color);
				}
			}
		
		exit_pong:;
		}

	}
}