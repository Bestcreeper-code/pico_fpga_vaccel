localparam logic [31:0] FB_BASE = 32'h0000_0000;
localparam int          FB_SIZE = 32'h0000_1000;  // 4K



module top_module
(
    //board lines
    input        I_clk,          // 27MHz board clock
    input        I_rst,
    // dvi
    output       O_tmds_clk_p,
    output       O_tmds_clk_n,
    output [2:0] O_tmds_data_p,
    output [2:0] O_tmds_data_n,
 
    //serial interface
    input        serial_dat_clk,//I_dma_clk,
    input        serial_dat_dir,//I_dma_word_sync,      // 1-tick: start of word
    inout  [3:0] serial_dat_bus,

    output        serial_dat_irq,
    input         serial_dat_rst,
    
    //leds for debug etc
    output [5:0]      _leds,

    //sdram interface
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,
    output O_sdram_cas_n,
    output O_sdram_ras_n,
    output O_sdram_wen_n,
    inout [31:0] IO_sdram_dq,
    output [10:0] O_sdram_addr,
    output [1:0] O_sdram_ba,
    output [3:0] O_sdram_dqm

);
    wire [5:0] leds;
    assign _leds = ~leds;

    wire I_rst_n = ~I_rst;

    
    //globals
    //system clock
    wire sys_clk = I_clk;


    // rgb
    wire [7:0] con_r;
    wire [7:0] con_g;
    wire [7:0] con_b;

//busses
    // dbus
    logic dbus_we;
    logic [31:0] dbus_addr;
    tri [31:0] dbus_data;
    logic dbus_ok;

    
 
    //fb bus
    wire fb_sel = (dbus_addr & ~(FB_SIZE-1)) == FB_BASE;
    wire fb_we  = dbus_we && fb_sel;
    wire [$clog2(FB_SIZE)-1:0] fb_addr_local = dbus_addr[$clog2(FB_SIZE)-1:0];
    logic fb_ok;



    assign dbus_ok = fb_ok;

//modules
    // serial interface
    logic serial_word_clk;
    logic [31:0] serial_rx_out;
    logic [31:0] serial_tx_in;
    
    qserial_interface #(
        .WORD_BITS (32)
    ) qserial_interface (
        .rst          (serial_dat_rst),

        .clk_in (serial_dat_clk),
        .is_rx (serial_dat_dir),
        .serial_data_bus (serial_dat_bus),
         
        
        .new_word     (serial_word_clk),
        .rx_word      (serial_rx_out),
        .tx_word      (serial_tx_in)
    );

    


    // command processor
    Command_Processor #(
        .WORD_BITS (32)
    ) cmd_proc (
        
        .sys_clk  (sys_clk),
        .rst_n (I_rst_n),

        // data flow
        .new_word_present_clk (serial_word_clk),
        .rx_data  (serial_rx_out),
        .tx_data  (serial_tx_in),

        // misc
        .irq      (serial_dat_irq),
        .leds     (leds),
            


        //databus
        .dbus_we (dbus_we),
        .dbus_addr (dbus_addr),
        .dbus_data (dbus_data),
        .dbus_ok (dbus_ok)
        
    );














/*
    // SDRAM controller interface
    
    // Controller clocks
    logic        I_sdrc_clk;
    logic        I_sdram_clk;

    
    ////////assign to same clk since it apparently is more stable?
    assign I_sdram_clk = I_sdrc_clk;
        

    // Controller command interface
    logic        I_sdrc_cmd_en;
    logic [2:0]  I_sdrc_cmd;

    // SDRAM control
    logic        I_sdrc_precharge_ctrl;
    logic        I_sdram_power_down;
    logic        I_sdram_selfrefresh;

    // SDRAM address
    logic [20:0] I_sdrc_addr;

    // Data mask
    logic [3:0]  I_sdrc_dqm;

    // Write data
    logic [31:0] I_sdrc_data;

    // Transfer length
    logic [7:0]  I_sdrc_data_len;

    // Read data
    logic [31:0] O_sdrc_data;

    // Controller status
    logic        O_sdrc_init_done;
    logic        O_sdrc_cmd_ack;

    // sdram controller

    SDRAM_Controller_HS g_sdram_controller
    (
        //sdram pins
        .O_sdram_clk   (O_sdram_clk),
        .O_sdram_cke   (O_sdram_cke),
        .O_sdram_cs_n  (O_sdram_cs_n),
        .O_sdram_cas_n (O_sdram_cas_n),
        .O_sdram_ras_n (O_sdram_ras_n),
        .O_sdram_wen_n (O_sdram_wen_n),

        .O_sdram_dqm   (O_sdram_dqm),
        .O_sdram_addr  (O_sdram_addr),
        .O_sdram_ba    (O_sdram_ba),
        .IO_sdram_dq   (IO_sdram_dq),

        //interface
        .I_sdrc_rst_n           (I_rst_n),
        .I_sdrc_clk             (I_sdrc_clk),
        .I_sdram_clk            (I_sdram_clk),

        .I_sdrc_cmd_en          (I_sdrc_cmd_en),
        .I_sdrc_cmd             (I_sdrc_cmd),

        .I_sdrc_precharge_ctrl  (I_sdrc_precharge_ctrl),
        .I_sdram_power_down     (I_sdram_power_down),
        .I_sdram_selfrefresh    (I_sdram_selfrefresh),

        .I_sdrc_addr            (I_sdrc_addr),
        .I_sdrc_dqm             (I_sdrc_dqm),
        .I_sdrc_data            (I_sdrc_data),
        .I_sdrc_data_len        (I_sdrc_data_len),

        .O_sdrc_data            (O_sdrc_data),
        .O_sdrc_init_done       (O_sdrc_init_done),
        .O_sdrc_cmd_ack         (O_sdrc_cmd_ack)
    );
*/























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





    
    framebuffer u_framebuffer (
        .pix_clk     (pix_clk),
        .rst_n       (hdmi_rst_n),
        .wr_clk      (sys_clk),
        .wr_rst_n    (I_rst_n),

        .x (x), .y (y),
        .r (con_r), .g (con_g), .b (con_b),

        .input_we    (fb_we),
        .input_addr  (fb_addr_local),
        .input_wdata (dbus_data[15:0]),
        .input_ok    (fb_ok)
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