#pragma once

#include <stdint.h>
#include "helpers/big_end.hpp"


typedef be_uint16_t color_t;

// RO status registers space

typedef enum {
    VACCEL_STATUS_BUSY        = 1u << 0,
    VACCEL_STATUS_ERROR       = 1u << 1,
    VACCEL_STATUS_IRQ_PENDING = 1u << 2,
    VACCEL_STATUS_FIFO_EMPTY  = 1u << 3,
    VACCEL_STATUS_FIFO_FULL   = 1u << 4,
    VACCEL_STATUS_VBLANK      = 1u << 5,
} vaccel_status_bits;

typedef enum {
    VACCEL_FLAG_AWAIT = 0x1,//needs the next part of the command data to be sent

} vaccel_flags;

typedef struct {
    uint32_t status;
    uint32_t error_code;
    uint32_t flags;
} __attribute__((packed)) vaccel_status_regs;


typedef enum  {
    VACCEL_CMD_SET_STATUS_LED = 0xDB,
    VACCEL_CMD_WRITE_LOHALF_BYTEADDR_DBUS = 0xF0,
    VACCEL_CMD_READ_LOHALF_BYTEADDR_DBUS = 0xF1
} vaccel_opcodes;


// commands
typedef struct {
    be_uint16_t command_length;
    uint8_t args;
    uint8_t opcode;
} __attribute__((packed)) vaccel_command_header;

typedef struct {
    vaccel_command_header header;
    be_uint16_t x,y;
    be_uint16_t w,h;
    color_t color;
} __attribute__((packed)) vaccel_command_draw_rect;