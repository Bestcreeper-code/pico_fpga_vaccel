#include "pico/stdio.h"
#include "hardware/dma.h"
#include "hardware/irq.h"
#include "pico/time.h"
#include "hardware/pio.h"
#include "build/qspi_dma.pio.h"
#include "serial_data/serial.h"
#include <hardware/gpio.h>
#include <hardware/timer.h>
#include <pico/types.h>
#include <stdint.h>
#include <stdio.h>



int pad1_y = 7;
int pad2_y = 7;

int ball_x = 15;
int ball_y = 15;

int ball_dx = 1;
int ball_dy = -1;

int main()
{
    stdio_init_all();
    sleep_ms(2000);

    printf("Starting...\n");
    serial_init();
    while (true) {

        char chr = getchar_timeout_us(10);

        switch (chr) {

        case 'z':
        case 'Z':
            if (pad1_y > 0)
                pad1_y--;
            break;

        case 's':
        case 'S':
            if (pad1_y < 27)
                pad1_y++;
            break;

        case 'o':
        case 'O':
            if (pad2_y > 0)
                pad2_y--;
            break;

        case 'l':
        case 'L':
            if (pad2_y < 27)
                pad2_y++;
            break;
        }

        static int ball_timer = 0;
        if (ball_timer++ >= 8) {

            ball_x += ball_dx;
            ball_y += ball_dy;
            ball_timer = 0;
        }

        if (ball_y < 0) {
            ball_y = 0;
            ball_dy = 1;
        }

        if (ball_y > 29) {
            ball_y = 29;
            ball_dy = -1;
        }

        if (ball_dx < 0 &&
            ball_x == 2 &&
            ball_y >= pad1_y &&
            ball_y < pad1_y + 3)
        {
            ball_dx = 1;
        }

        if (ball_dx > 0 &&
            ball_x == 29 &&
            ball_y >= pad2_y &&
            ball_y < pad2_y + 3)
        {
            ball_dx = -1;
        }

        if (ball_x < 0 || ball_x > 31) {
            ball_x = 15;
            ball_y = 15;
            ball_dx = -ball_dx;
        }

        fill_dma_buffer(0x0000);

        for (int i = 0; i < 3; i++) {
            put_pix(1,  pad1_y + i, 0xF800);
            put_pix(30, pad2_y + i, 0x07E0);
        }

        put_pix(ball_x, ball_y, 0xFFFE);

        sleep_ms(16);
    }
}