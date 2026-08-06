module command_processor (
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






basic_16b_semidpb your_instance_name(
        .dout(dout), 
        .clka(clka), 
        .cea(cea), 
        .reseta(reseta),
        .clkb(clkb),
        .ceb(ceb),
        .resetb(resetb),
        .oce(oce),
        .ada(ada),
        .din(din),
        .adb(adb)
    );