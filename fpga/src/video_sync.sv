// ---------------------------------------------------------------------
// video_sync.sv
// Pure video timing generator: hs/vs/de + visible-area pixel counters.
// No pixel content here at all -- swap resolutions by changing the
// parameters, independent of whatever draws the picture.
// ---------------------------------------------------------------------
module video_sync #(
    parameter int H_TOTAL  = 1650,
    parameter int H_SYNC   = 40,
    parameter int H_BPORCH = 220,
    parameter int H_RES    = 1280,
    parameter int V_TOTAL  = 750,
    parameter int V_SYNC   = 5,
    parameter int V_BPORCH = 20,
    parameter int V_RES    = 720,
    parameter bit HS_POL   = 1'b1,   // 1 = active-high sync pulse
    parameter bit VS_POL   = 1'b1
)(
    input  logic        clk,      // pixel clock
    input  logic         rst_n,    // async, low active

    output logic        de,       // display-enable, aligned with x/y below
    output logic        hs,
    output logic        vs,

    output logic [11:0] x,        // 0..H_RES-1, valid while de=1
    output logic [11:0] y,        // 0..V_RES-1, valid while de=1
    output logic        frame_tick // 1-cycle pulse at start of vsync
);

    localparam int N = 5; // output pipeline depth, mirrors original module

    logic [11:0] h_cnt, v_cnt;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) h_cnt <= 12'd0;
        else if (h_cnt >= H_TOTAL-1) h_cnt <= 12'd0;
        else h_cnt <= h_cnt + 12'd1;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) v_cnt <= 12'd0;
        else if (v_cnt >= V_TOTAL-1 && h_cnt >= H_TOTAL-1) v_cnt <= 12'd0;
        else if (h_cnt >= H_TOTAL-1) v_cnt <= v_cnt + 12'd1;

    logic de_w, hs_w, vs_w;
    assign de_w = (h_cnt >= H_SYNC+H_BPORCH) && (h_cnt < H_SYNC+H_BPORCH+H_RES) &&
                  (v_cnt >= V_SYNC+V_BPORCH) && (v_cnt < V_SYNC+V_BPORCH+V_RES);
    assign hs_w = ~(h_cnt < H_SYNC);
    assign vs_w = ~(v_cnt < V_SYNC);

    logic [N-1:0] de_dn, hs_dn, vs_dn;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            de_dn <= '0;
            hs_dn <= '1;
            vs_dn <= '1;
        end else begin
            de_dn <= {de_dn[N-2:0], de_w};
            hs_dn <= {hs_dn[N-2:0], hs_w};
            vs_dn <= {vs_dn[N-2:0], vs_w};
        end

    assign de = de_dn[4];

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            hs <= 1'b1;
            vs <= 1'b1;
        end else begin
            hs <= HS_POL ? ~hs_dn[3] : hs_dn[3];
            vs <= VS_POL ? ~vs_dn[3] : vs_dn[3];
        end

    // visible-area pixel coordinate, same edge-detect trick as the
    // original De_hcnt/De_vcnt but exposed as a clean x/y pair
    logic de_d1, vs_d1;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) de_d1 <= 1'b0;
        else de_d1 <= de_dn[1];

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) vs_d1 <= 1'b1;
        else vs_d1 <= vs_dn[1];

    logic de_pos, de_neg, vs_pos;
    assign de_pos = !de_d1 &  de_dn[1];
    assign de_neg =  de_d1 & !de_dn[1];
    assign vs_pos = !vs_d1 &  vs_dn[1];

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) x <= 12'd0;
        else if (de_pos) x <= 12'd0;
        else if (de_dn[1]) x <= x + 12'd1;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) y <= 12'd0;
        else if (vs_pos) y <= 12'd0;
        else if (de_neg) y <= y + 12'd1;

    assign frame_tick = vs_pos;

endmodule