module TMDS_rPLL #(
    parameter integer RESOLUTION = 720,
    parameter integer REFRESH_HZ = 60
)(
    clkout,
    lock,
    clkin
);

output clkout;
output lock;
input clkin;

wire clkoutp_o;
wire clkoutd_o;
wire clkoutd3_o;
wire gw_gnd;

assign gw_gnd = 1'b0;



localparam integer MODE =
    (RESOLUTION == 1080 && REFRESH_HZ == 60) ? 3 :
    (RESOLUTION == 1080 && REFRESH_HZ == 30) ? 4 :
    (RESOLUTION == 720  && REFRESH_HZ == 60) ? 1 :
    (RESOLUTION == 720  && REFRESH_HZ == 30) ? 2 :
    (RESOLUTION == 480  && REFRESH_HZ == 60) ? 5 :
                                                1;


// 27 MHz in
//pix clk=
// 720p60 74.25 MHz
// 720p30 37.125 MHz
// 1080p60 148.5 MHz 
// 1080p30 74.25 MHz 
// 480p60 25.2 MHz
localparam integer IDIV_SEL =
    (MODE == 1) ? 3 :
    (MODE == 2) ? 7 :
    (MODE == 3) ? 3 :
    (MODE == 4) ? 3 :
    (MODE == 5) ? 2 :    // was 3 — WRONG
                  3;
localparam integer FBDIV_SEL =
    (MODE == 1) ? 54 :
    (MODE == 2) ? 54 :
    (MODE == 3) ? 109 :
    (MODE == 4) ? 54 :
    (MODE == 5) ? 13 :   // was 26 — WRONG, gave 36.45 MHz not 25.2 MHz
                  54;
localparam integer ODIV_SEL =
    (MODE == 1) ? 2 :
    (MODE == 2) ? 4 :
    (MODE == 3) ? 1 :
    (MODE == 4) ? 2 :
    (MODE == 5) ? 8 :    // was 1 — WRONG, VCO would be out of range
                  2;


rPLL rpll_inst (
    .CLKOUT(clkout),
    .LOCK(lock),

    .CLKOUTP(clkoutp_o),
    .CLKOUTD(clkoutd_o),
    .CLKOUTD3(clkoutd3_o),

    .RESET(gw_gnd),
    .RESET_P(gw_gnd),

    .CLKIN(clkin),
    .CLKFB(gw_gnd),

    .FBDSEL({6{gw_gnd}}),
    .IDSEL ({6{gw_gnd}}),
    .ODSEL ({6{gw_gnd}}),
    .PSDA  ({4{gw_gnd}}),
    .DUTYDA({4{gw_gnd}}),
    .FDLY  ({4{gw_gnd}})
);


defparam rpll_inst.FCLKIN = "27";

defparam rpll_inst.IDIV_SEL  = IDIV_SEL;
defparam rpll_inst.FBDIV_SEL = FBDIV_SEL;
defparam rpll_inst.ODIV_SEL  = ODIV_SEL;

defparam rpll_inst.DYN_IDIV_SEL  = "false";
defparam rpll_inst.DYN_FBDIV_SEL = "false";
defparam rpll_inst.DYN_ODIV_SEL  = "false";

defparam rpll_inst.CLKFB_SEL = "internal";

defparam rpll_inst.CLKOUT_BYPASS  = "false";
defparam rpll_inst.CLKOUTP_BYPASS = "false";
defparam rpll_inst.CLKOUTD_BYPASS = "false";

defparam rpll_inst.DEVICE = "GW2AR-18C";

endmodule