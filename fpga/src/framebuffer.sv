module framebuffer (
    input  logic        pix_clk,
    input  logic        rst_n,

    input  logic        wr_clk,
    input  logic        wr_rst_n,

    input  logic [11:0] x,
    input  logic [11:0] y,

    input  logic        input_we,
    input  logic [9:0]  input_addr,
    input  logic [15:0] input_wdata,

    output logic [7:0]  r,
    output logic [7:0]  g,
    output logic [7:0]  b
);

    localparam int FB_W = 32;
    localparam int FB_H = 30;

    localparam int CELL_SIZE = 24;

    // 1280x720 screen, framebuffer is 768x720
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


    // BRAM address
    logic [9:0] adb;

    assign adb = row * FB_W + col;


    // BRAM read latency alignment

    logic [9:0] adb_d1;
    logic [9:0] adb_d2;

    logic blank;
    logic blank_d1;
    logic blank_d2;


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



    logic [15:0] dout;


    framebuffer_sdpb framebuffer_inst (
        .clka   (wr_clk),
        .cea    (input_we),
        .reseta (~wr_rst_n),

        .ada    (input_addr),
        .din    (input_wdata),

        .clkb   (pix_clk),
        .ceb    (1'b1),
        .resetb (~rst_n),
        .oce    (1'b1),

        .adb    (adb_d2),
        .dout   (dout)
    );



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


endmodule