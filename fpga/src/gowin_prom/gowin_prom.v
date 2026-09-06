//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Sun Sep  6 12:04:50 2026

module Gowin_pROM (dout, clk, oce, ce, reset, ad);

output [127:0] dout;
input clk;
input oce;
input ce;
input reset;
input [0:0] ad;

wire gw_gnd;

assign gw_gnd = 1'b0;

pROM prom_inst_0 (
    .DO(dout[31:0]),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,ad[0],gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam prom_inst_0.READ_MODE = 1'b0;
defparam prom_inst_0.BIT_WIDTH = 32;
defparam prom_inst_0.RESET_MODE = "SYNC";

pROM prom_inst_1 (
    .DO(dout[63:32]),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,ad[0],gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam prom_inst_1.READ_MODE = 1'b0;
defparam prom_inst_1.BIT_WIDTH = 32;
defparam prom_inst_1.RESET_MODE = "SYNC";

pROM prom_inst_2 (
    .DO(dout[95:64]),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,ad[0],gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam prom_inst_2.READ_MODE = 1'b0;
defparam prom_inst_2.BIT_WIDTH = 32;
defparam prom_inst_2.RESET_MODE = "SYNC";

pROM prom_inst_3 (
    .DO(dout[127:96]),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,ad[0],gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam prom_inst_3.READ_MODE = 1'b0;
defparam prom_inst_3.BIT_WIDTH = 32;
defparam prom_inst_3.RESET_MODE = "SYNC";

endmodule //Gowin_pROM
