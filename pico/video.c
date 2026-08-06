#include "video.h"
#include "build/qspi_dma.pio.h"
#include <hardware/dma.h>
#include <hardware/pio.h>
#include <pico/time.h>
#include <stdio.h>

#define FB_WORDS 1024
#define RX_WORDS 16
#define PIO_CLKDIV 2

uint16_t _internal_framebuffer[FB_WORDS] = {[0 ... FB_WORDS-1] = 0x8410};
uint16_t* dma_framebuffer = &_internal_framebuffer[0];

volatile uint16_t rx_debug_buffer[RX_WORDS];

#define TX_DATA_PIN_BASE 6
#define RX_DATA_PIN_BASE 8
#define DMA_CLK_PIN 10
#define DMA_SYNC_PIN 11
#define DMA_DEV_RST_PIN 13

static int tx_dma_chan;
static int rx_dma_chan;

static PIO link_pio = pio0;
static uint link_sm = 0;


/*
TX DMA
loops the fb forever.
*/
static int tx_dma_chan;
static int tx_ctrl_chan;

static void init_tx_dma(uintptr_t buf_addr, size_t transfers, uint dreq)
{
    tx_dma_chan = dma_claim_unused_channel(true);
    tx_ctrl_chan = dma_claim_unused_channel(true);

    dma_channel_config data_cfg =
        dma_channel_get_default_config(tx_dma_chan);

    channel_config_set_transfer_data_size(
        &data_cfg,
        DMA_SIZE_16
    );

    channel_config_set_read_increment(
        &data_cfg,
        true
    );

    channel_config_set_write_increment(
        &data_cfg,
        false
    );

    channel_config_set_dreq(
        &data_cfg,
        dreq
    );

    channel_config_set_chain_to(
        &data_cfg,
        tx_ctrl_chan
    );


    dma_channel_config ctrl_cfg =
        dma_channel_get_default_config(tx_ctrl_chan);

    channel_config_set_transfer_data_size(
        &ctrl_cfg,
        DMA_SIZE_32
    );

    channel_config_set_read_increment(
        &ctrl_cfg,
        false
    );

    channel_config_set_write_increment(
        &ctrl_cfg,
        false
    );

    channel_config_set_chain_to(
        &ctrl_cfg,
        tx_dma_chan
    );


    dma_channel_configure(
        tx_dma_chan,
        &data_cfg,
        &link_pio->txf[link_sm],
        (void*)buf_addr,
        transfers,
        false
    );


    // reload read address + transfer count
    static uint32_t reload[2];

    reload[0] = (uint32_t)buf_addr;
    reload[1] = transfers;


    dma_channel_configure(
        tx_ctrl_chan,
        &ctrl_cfg,
        &dma_hw->ch[tx_dma_chan].read_addr,
        reload,
        2,
        false
    );


    dma_channel_start(tx_dma_chan);
}



//RX DMA

static void init_rx_dma(uintptr_t buf_addr, size_t transfers, uint dreq)
{
    rx_dma_chan = dma_claim_unused_channel(true);

    dma_channel_config cfg = dma_channel_get_default_config(rx_dma_chan);

    channel_config_set_transfer_data_size(&cfg, DMA_SIZE_16);
    channel_config_set_read_increment(&cfg, false);
    channel_config_set_write_increment(&cfg, true);
    channel_config_set_dreq(&cfg, dreq);

    channel_config_set_ring(&cfg, true, 5);

    dma_channel_configure(
        rx_dma_chan,
        &cfg,
        (void *)buf_addr,
        &link_pio->rxf[link_sm],
        transfers,
        false
    );

    dma_channel_start(rx_dma_chan);
}


static void init_duplex_link()
{
    uint offset = pio_add_program(link_pio, &duplex_sync_program);

    pio_sm_config c =
        duplex_sync_program_get_default_config(offset);


    sm_config_set_out_pins(&c, TX_DATA_PIN_BASE, 2);
    sm_config_set_in_pins(&c, RX_DATA_PIN_BASE);

    sm_config_set_sideset_pins(&c, DMA_CLK_PIN);


    // pull/push per word
    sm_config_set_out_shift(
        &c,
        false,
        true,
        16
    );

    sm_config_set_in_shift(
        &c,
        false,
        true,
        16
    );


    sm_config_set_clkdiv(&c, PIO_CLKDIV);//~= 20.8MHz i think


    for (uint i = 0; i < 2; i++) {
        pio_gpio_init(link_pio, TX_DATA_PIN_BASE + i);
        pio_gpio_init(link_pio, RX_DATA_PIN_BASE + i);
    }

    pio_gpio_init(link_pio, DMA_CLK_PIN);
    pio_gpio_init(link_pio, DMA_SYNC_PIN);


    pio_sm_set_consecutive_pindirs(
        link_pio,
        link_sm,
        TX_DATA_PIN_BASE,
        2,
        true
    );

    pio_sm_set_consecutive_pindirs(
        link_pio,
        link_sm,
        RX_DATA_PIN_BASE,
        2,
        false
    );

    
    
    //bit0 = CLK
    //bit1 = SYNC
    pio_sm_set_consecutive_pindirs(
        link_pio,
        link_sm,
        DMA_CLK_PIN,
        2,
        true
    );


    
    
    pio_sm_init(
        link_pio,
        link_sm,
        offset,
        &c
    );

    pio_sm_set_pins_with_mask(
        link_pio,
        link_sm,
        0,
        (1u << DMA_CLK_PIN) |
        (1u << DMA_SYNC_PIN)
    );
}


static void init_device_dma()
{
    gpio_init(DMA_DEV_RST_PIN);
    gpio_set_dir(DMA_DEV_RST_PIN, GPIO_OUT);

    gpio_put(DMA_DEV_RST_PIN, 0);
    sleep_us(10);
    gpio_put(DMA_DEV_RST_PIN, 1);


    for (int i = 0; i < RX_WORDS; i++)
        rx_debug_buffer[i] = 0;


    init_duplex_link();

    pio_sm_clear_fifos(
        link_pio,
        link_sm
    );

    pio_sm_restart(
        link_pio,
        link_sm
    );

    init_tx_dma(
        (uintptr_t)_internal_framebuffer,
        FB_WORDS,
        pio_get_dreq(link_pio, link_sm, true)
    );


    // init_rx_dma(
    //     (uintptr_t)rx_debug_buffer,
    //     RX_WORDS,
    //     pio_get_dreq(link_pio, link_sm, false)
    // );

    pio_sm_set_enabled(
        link_pio,
        link_sm,
        true
    );
}


void fill_dma_buffer(uint16_t color)
{
    for (int i = 0; i < FB_WORDS; i++)
        _internal_framebuffer[i] = color;
}


int video_init()
{
    fill_dma_buffer(0x8410);

    init_device_dma();


    printf(
        "TX DMA channel: %d\n",
        tx_dma_chan
    );

    printf(
        "RX DMA channel: %d\n",
        rx_dma_chan
    );

    return 0;
}


void link_debug_dump()
{
    uint32_t fdebug = link_pio->fdebug;

    bool rxstall =
        fdebug &
        (1u << (PIO_FDEBUG_RXSTALL_LSB + link_sm));

    bool txstall =
        fdebug &
        (1u << (PIO_FDEBUG_TXSTALL_LSB + link_sm));


    uint32_t flevel = link_pio->flevel;

    uint32_t tx_level =
        (flevel >> (link_sm * 8)) & 0xF;

    uint32_t rx_level =
        (flevel >> (link_sm * 8 + 4)) & 0xF;


    uint32_t pc =
        pio_sm_get_pc(link_pio, link_sm);


    bool enabled =
        (link_pio->ctrl >> link_sm) & 1;


    printf(
        "SM=%d PC=%u TXstall=%d RXstall=%d TXlvl=%u RXlvl=%u\n",
        enabled,
        pc,
        txstall,
        rxstall,
        tx_level,
        rx_level
    );


    printf(
        "TX busy=%d RX busy=%d\n",
        dma_channel_is_busy(tx_dma_chan),
        dma_channel_is_busy(rx_dma_chan)
    );
}