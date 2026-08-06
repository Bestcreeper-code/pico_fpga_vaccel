#pragma once

#include <stdint.h>
#define CURRENT_DMA_BITSIZE DMA_SIZE_16
#define CURRENT_PIO_PULL_THRESHOLD 16

typedef uint16_t c565_t;

extern volatile uint32_t fpga_resync_events;


extern uint16_t* dma_framebuffer;

int video_init();
void fill_dma_buffer(uint16_t color);

void link_debug_dump();