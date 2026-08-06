module top_module
(
    input        I_clk,          // 27MHz board clock
    input        I_rst,
    input        dma_soft_rst,
    output       O_tmds_clk_p,
    output       O_tmds_clk_n,
    output [2:0] O_tmds_data_p,
    output [2:0] O_tmds_data_n,

    // framebuffer DMA / duplex serial interface
    input        I_dma_clk,
    input        I_dma_word_sync,      // 1-tick: start of word
    input  [1:0] tx_in,
    output [1:0] rx_out,

    output [1:0]      leds
    //output       led1
    //output       led2
    //output       led3

);

    wire I_rst_n = ~I_rst;

    //DVI clocking 

    wire serial_clk;
    wire pix_clk;
    wire pll_lock;

    wire hdmi_rst_n = I_rst_n & pll_lock;


    TMDS_rPLL #(
        .RESOLUTION(720),
        .REFRESH_HZ(60)
    ) u_tmds_rpll (
        .clkin  (I_clk),
        .clkout (serial_clk),
        .lock   (pll_lock)
    );


    CLKDIV u_clkdiv (
        .RESETN (hdmi_rst_n),
        .HCLKIN (serial_clk),
        .CLKOUT (pix_clk),
        .CALIB  (1'b1)
    );

    defparam u_clkdiv.DIV_MODE = "5";
    defparam u_clkdiv.GSREN    = "false";


    // video timing

    wire        de;
    wire        hs;
    wire        vs;
    wire [11:0] x;
    wire [11:0] y;


    video_sync #(
        .H_TOTAL(1650), .H_SYNC(40), .H_BPORCH(220), .H_RES(1280),
        .V_TOTAL(750),  .V_SYNC(5),  .V_BPORCH(20),  .V_RES(720),
        .HS_POL(1'b1),  .VS_POL(1'b1)
    ) u_video_sync (
        .clk        (pix_clk),
        .rst_n      (hdmi_rst_n),
        .de         (de),
        .hs         (hs),
        .vs         (vs),
        .x          (x),
        .y          (y),
        .frame_tick ()
    );


    // framebuffer

    localparam int FB_W   = 32;
    localparam int FB_H   = 30;
    localparam int ADDR_W = 10;


    wire [7:0] con_r;
    wire [7:0] con_g;
    wire [7:0] con_b;


    
    // Framebuffer DMA writer

    localparam int DMA_ADDRESS_BUS_SIZE = ADDR_W + 1;   

    logic dma_we;
    logic [15:0] dma_data_bus_out;
    logic [DMA_ADDRESS_BUS_SIZE-1:0] dma_addr_bus;
    logic dma_data_bus_clk;

    
    


    serial_stream_dma_interface #(
        .WORD_BITS        (16),
        .ADDRESS_BUS_SIZE (DMA_ADDRESS_BUS_SIZE)
    ) u_fb_dma (
        .clk_in       (I_dma_clk),
        .sync_in      (I_dma_word_sync),
        .rst          (dma_soft_rst),

        .tx_in        (tx_in),
        .rx_out       (rx_out),
        .rx_tx_word   (16'h0000), //TODO: wire it to some logic

        .leds (leds),

        .data_bus_clk (dma_data_bus_clk),
        .we           (dma_we),
        .data_bus_out (dma_data_bus_out),
        .addr_bus     (dma_addr_bus)
    );


    framebuffer u_framebuffer (
        .pix_clk   (pix_clk),
        .rst_n     (hdmi_rst_n),

        
        .wr_clk    (dma_data_bus_clk),
        .wr_rst_n  (I_rst_n),

        // read port
        .x (x),
        .y (y),

        .r (con_r),
        .g (con_g),
        .b (con_b),

        
        .input_we    (dma_we),
        .input_addr  (dma_addr_bus[DMA_ADDRESS_BUS_SIZE-1:0]),
        .input_wdata (dma_data_bus_out)
    );


    // framebuffer output pipeline

    reg [7:0] r_d;
    reg [7:0] g_d;
    reg [7:0] b_d;


    always @(posedge pix_clk) begin
        r_d <= con_r;
        g_d <= con_g;
        b_d <= con_b;
    end



    // DVI transmitter


    DVI_TX_Top DVI_TX_Top_inst (

        .I_rst_n       (hdmi_rst_n),

        .I_serial_clk  (serial_clk),
        .I_rgb_clk     (pix_clk),

        .I_rgb_vs      (vs),
        .I_rgb_hs      (hs),
        .I_rgb_de      (de),

        .I_rgb_r       (r_d),
        .I_rgb_g       (g_d),
        .I_rgb_b       (b_d),

        .O_tmds_clk_p  (O_tmds_clk_p),
        .O_tmds_clk_n  (O_tmds_clk_n),

        .O_tmds_data_p (O_tmds_data_p),
        .O_tmds_data_n (O_tmds_data_n)
    );


endmodule