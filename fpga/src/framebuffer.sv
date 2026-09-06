module framebuffer (
    input  logic        pix_clk,
    input  logic        rst_n,
    input  logic        wr_clk,
    input  logic        wr_rst_n,
    input  logic [11:0] x,
    input  logic [11:0] y,
    input  logic        input_we,
    input  logic [15:0] input_addr,
    input  logic [15:0] input_wdata,
    output logic        input_ok,
    output logic [7:0]  r,
    output logic [7:0]  g,
    output logic [7:0]  b
);
    localparam int FB_W = 32;
    localparam int FB_H = 30;
    localparam int CELL_SIZE = 24;
    localparam int X_OFFSET = (1280 - (FB_W * CELL_SIZE)) / 2;

    logic [4:0] col;
    logic [4:0] row;
    logic visible;

    assign visible =
        (x >= X_OFFSET) &&
        (x < X_OFFSET + FB_W*CELL_SIZE) &&
        (y < FB_H*CELL_SIZE);

    assign col = (x - X_OFFSET) / CELL_SIZE;
    assign row = y / CELL_SIZE;

    //  video side read
    logic [9:0] adb;
    assign adb = row * FB_W + col;

    logic [9:0] adb_d1, adb_d2;
    logic blank, blank_d1, blank_d2;
    assign blank = !visible;

    always_ff @(posedge pix_clk or negedge rst_n) begin
        if (!rst_n) begin
            adb_d1   <= 10'd0;
            adb_d2   <= 10'd0;
            blank_d1 <= 1'b1;
            blank_d2 <= 1'b1;
        end else begin
            adb_d1 <= adb;
            adb_d2 <= adb_d1;
            blank_d1 <= blank;
            blank_d2 <= blank_d1;
        end
    end

    // dbus side write
    localparam int FB_CELLS     = FB_W * FB_H;        // 960
    localparam int FB_ADDR_BITS = $clog2(FB_CELLS);   // 10

    logic [FB_ADDR_BITS-1:0] ada;
    assign ada = input_addr[FB_ADDR_BITS-1:0];

    
    logic addr_in_range;
    assign addr_in_range = (ada < FB_CELLS[FB_ADDR_BITS-1:0]);

    logic we_gated;
    assign we_gated = input_we && addr_in_range;

    logic [15:0] dout;

    framebuffer_sdpb framebuffer_inst (
        .clka   (wr_clk),
        .cea    (we_gated),
        .reseta (~wr_rst_n),
        .ada    (ada),
        .din    (input_wdata),

        .clkb   (pix_clk),
        .ceb    (1'b1),
        .resetb (~rst_n),
        .oce    (1'b1),
        .adb    (adb_d2),
        .dout   (dout)
    );

    
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            input_ok <= 1'b0;
        else
            input_ok <= we_gated;
    end

    // RGB565 -> RGB888
    always_comb begin
        if (blank_d2) begin
            r = 8'd0;
            g = 8'd0;
            b = 8'd0;
        end else begin
            r = {dout[15:11], dout[15:13]};
            g = {dout[10:5],  dout[10:9]};
            b = {dout[4:0],   dout[4:2]};
        end
    end

    logic [15:0] tile_douta, tile_doutb;
    logic [13:0] tile_ada  = '0;
    logic [13:0] tile_adb  = '0;
    logic [15:0] tile_dina = '0;
    logic [15:0] tile_dinb = '0;

    DPBRAM_16k_565 tile_ram (
        .douta  (tile_douta),
        .doutb  (tile_doutb),
        .clka   (wr_clk),
        .ocea   (1'b0),
        .cea    (1'b0),
        .reseta (~wr_rst_n),
        .wrea   (1'b0),
        .clkb   (pix_clk),
        .oceb   (1'b0),
        .ceb    (1'b0),
        .resetb (~rst_n),
        .wreb   (1'b0),
        .ada    (tile_ada),
        .dina   (tile_dina),
        .adb    (tile_adb),
        .dinb   (tile_dinb)
    );

endmodule