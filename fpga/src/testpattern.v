// ---------------------------------------------------------------------
// File name         : testpattern.v
// Module name       : testpattern
// Created by        : Caojie
// Module Description: 
//						I_mode[2:0] = "000" : color bar     
//						I_mode[2:0] = "001" : net grid     
//						I_mode[2:0] = "010" : static RGB triangle (edge-function rasterized)
//						I_mode[2:0] = "011" : single green
//                      I_mode[2:0] = "100" : single blue
//                      I_mode[2:0] = "101" : single red
//                
// ---------------------------------------------------------------------
// Release history
// VERSION |   Date      | AUTHOR  |    DESCRIPTION
// --------------------------------------------------------------------
//   1.0   | 24-Sep-2009 | Caojie  |    initial
//   1.1   | 19-Jul-2026 | fix     |    replaced ad-hoc triangle fill with
//                                       proper edge-function rasterization +
//                                       exact-shift barycentric color blend;
//                                       fixed single-color mode mapping
// --------------------------------------------------------------------

module testpattern
(
	input              I_pxl_clk   ,//pixel clock
    input              I_rst_n     ,//low active 
    input      [2:0]   I_mode      ,//data select
    input      [7:0]   I_single_r  ,
    input      [7:0]   I_single_g  ,
    input      [7:0]   I_single_b  ,
    input      [11:0]  I_h_total   ,//hor total time 
    input      [11:0]  I_h_sync    ,//hor sync time
    input      [11:0]  I_h_bporch  ,//hor back porch
    input      [11:0]  I_h_res     ,//hor resolution
    input      [11:0]  I_v_total   ,//ver total time 
    input      [11:0]  I_v_sync    ,//ver sync time  
    input      [11:0]  I_v_bporch  ,//ver back porch  
    input      [11:0]  I_v_res     ,//ver resolution 
    input              I_hs_pol    ,//HS polarity 
    input              I_vs_pol    ,//VS polarity 
    output             O_de        ,   
    output reg         O_hs        ,
    output reg         O_vs        ,
    output     [7:0]   O_data_r    ,    
    output     [7:0]   O_data_g    ,
    output     [7:0]   O_data_b    
); 

//====================================================
localparam N = 5; //delay N clocks

localparam	WHITE	= {8'd255 , 8'd255 , 8'd255 };//{B,G,R}
localparam	YELLOW	= {8'd0   , 8'd255 , 8'd255 };
localparam	CYAN	= {8'd255 , 8'd255 , 8'd0   };
localparam	GREEN	= {8'd0   , 8'd255 , 8'd0   };
localparam	MAGENTA	= {8'd255 , 8'd0   , 8'd255 };
localparam	RED		= {8'd0   , 8'd0   , 8'd255 };
localparam	BLUE	= {8'd255 , 8'd0   , 8'd0   };
localparam	BLACK	= {8'd0   , 8'd0   , 8'd0   };
  
//====================================================
reg  [11:0]   V_cnt     ;
reg  [11:0]   H_cnt     ;
              
wire          Pout_de_w    ;                          
wire          Pout_hs_w    ;
wire          Pout_vs_w    ;

reg  [N-1:0]  Pout_de_dn   ;                          
reg  [N-1:0]  Pout_hs_dn   ;
reg  [N-1:0]  Pout_vs_dn   ;

//----------------------------
wire 		  De_pos;
wire 		  De_neg;
wire 		  Vs_pos;
	
reg  [11:0]   De_vcnt     ;
reg  [11:0]   De_hcnt     ;
reg  [11:0]   De_hcnt_d1  ;
reg  [11:0]   De_hcnt_d2  ;

//-------------------------
//Color bar 
reg  [11:0]   Color_trig_num; 
reg           Color_trig    ;
reg  [3:0]    Color_cnt     ;
reg  [23:0]   Color_bar     ;

//----------------------------
//Net grid 
reg           Net_h_trig;
reg           Net_v_trig;
wire [1:0]    Net_pos   ;
reg  [23:0]   Net_grid  ;

//----------------------------
//Gray  
reg  [23:0]   Gray;
reg  [23:0]   Gray_d1;

//-----------------------------
wire [23:0]   Single_color;

//-------------------------------
wire [23:0]   Data_sel;

//-------------------------------
reg  [23:0]   Data_tmp/*synthesis syn_keep=1*/;

//==============================================================================
//Generate HS, VS, DE signals
always@(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		V_cnt <= 12'd0;
	else     
		begin
			if((V_cnt >= (I_v_total-1'b1)) && (H_cnt >= (I_h_total-1'b1)))
				V_cnt <= 12'd0;
			else if(H_cnt >= (I_h_total-1'b1))
				V_cnt <=  V_cnt + 1'b1;
			else
				V_cnt <= V_cnt;
		end
end

//-------------------------------------------------------------    
always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		H_cnt <=  12'd0; 
	else if(H_cnt >= (I_h_total-1'b1))
		H_cnt <=  12'd0 ; 
	else 
		H_cnt <=  H_cnt + 1'b1 ;           
end

//-------------------------------------------------------------
assign  Pout_de_w = ((H_cnt>=(I_h_sync+I_h_bporch))&(H_cnt<=(I_h_sync+I_h_bporch+I_h_res-1'b1)))&
                    ((V_cnt>=(I_v_sync+I_v_bporch))&(V_cnt<=(I_v_sync+I_v_bporch+I_v_res-1'b1))) ;
assign  Pout_hs_w =  ~((H_cnt>=12'd0) & (H_cnt<=(I_h_sync-1'b1))) ;
assign  Pout_vs_w =  ~((V_cnt>=12'd0) & (V_cnt<=(I_v_sync-1'b1))) ;  

//-------------------------------------------------------------
always@(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		begin
			Pout_de_dn  <= {N{1'b0}};                          
			Pout_hs_dn  <= {N{1'b1}};
			Pout_vs_dn  <= {N{1'b1}}; 
		end
	else 
		begin
			Pout_de_dn  <= {Pout_de_dn[N-2:0],Pout_de_w};                          
			Pout_hs_dn  <= {Pout_hs_dn[N-2:0],Pout_hs_w};
			Pout_vs_dn  <= {Pout_vs_dn[N-2:0],Pout_vs_w}; 
		end
end

assign O_de = Pout_de_dn[4];

always@(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		begin                        
			O_hs  <= 1'b1;
			O_vs  <= 1'b1; 
		end
	else 
		begin                         
			O_hs  <= I_hs_pol ? ~Pout_hs_dn[3] : Pout_hs_dn[3] ;
			O_vs  <= I_vs_pol ? ~Pout_vs_dn[3] : Pout_vs_dn[3] ;
		end
end

//=================================================================================
//Test Pattern
assign De_pos	= !Pout_de_dn[1] & Pout_de_dn[0]; //de rising edge
assign De_neg	= Pout_de_dn[1] && !Pout_de_dn[0];//de falling edge
assign Vs_pos	= !Pout_vs_dn[1] && Pout_vs_dn[0];//vs rising edge

always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		De_hcnt <= 12'd0;
	else if (De_pos == 1'b1)
		De_hcnt <= 12'd0;
	else if (Pout_de_dn[1] == 1'b1)
		De_hcnt <= De_hcnt + 1'b1;
	else
		De_hcnt <= De_hcnt;
end

always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n) 
		De_vcnt <= 12'd0;
	else if (Vs_pos == 1'b1)
		De_vcnt <= 12'd0;
	else if (De_neg == 1'b1)
		De_vcnt <= De_vcnt + 1'b1;
	else
		De_vcnt <= De_vcnt;
end

//---------------------------------------------------
//Color bar
//---------------------------------------------------
always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Color_trig_num <= 12'd0;
	else if (Pout_de_dn[1] == 1'b0)
		Color_trig_num <= I_h_res[11:3]; 
	else if ((Color_trig == 1'b1) && (Pout_de_dn[1] == 1'b1))
		Color_trig_num <= Color_trig_num + I_h_res[11:3];
	else
		Color_trig_num <= Color_trig_num;
end

always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Color_trig <= 1'b0;
	else if (De_hcnt == (Color_trig_num-1'b1)) 
		Color_trig <= 1'b1;
	else
		Color_trig <= 1'b0;
end

always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Color_cnt <= 3'd0;
	else if (Pout_de_dn[1] == 1'b0)
		Color_cnt <= 3'd0;
	else if ((Color_trig == 1'b1) && (Pout_de_dn[1] == 1'b1))
		Color_cnt <= Color_cnt + 1'b1;
	else
		Color_cnt <= Color_cnt;
end

always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Color_bar <= 24'd0;
	else if(Pout_de_dn[2] == 1'b1)
		case(Color_cnt)
			3'd0	:	Color_bar	<=	WHITE  ;
			3'd1	:	Color_bar	<=	YELLOW ;
			3'd2	:	Color_bar	<=	CYAN   ;
			3'd3	:	Color_bar	<=	GREEN  ;
			3'd4	:	Color_bar	<=	MAGENTA;
			3'd5	:	Color_bar	<=	RED    ;
			3'd6	:	Color_bar	<=	BLUE   ;
			3'd7	:	Color_bar	<=	BLACK  ;
			default	:	Color_bar	<=	BLACK  ;
		endcase
	else
		Color_bar	<=	BLACK  ;
end

//---------------------------------------------------
//Net grid
//---------------------------------------------------
always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Net_h_trig <= 1'b0;
	else if (((De_hcnt[4:0] == 5'd0) || (De_hcnt == (I_h_res-1'b1))) && (Pout_de_dn[1] == 1'b1))
		Net_h_trig <= 1'b1;
	else
		Net_h_trig <= 1'b0;
end

always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Net_v_trig <= 1'b0;
	else if (((De_vcnt[4:0] == 5'd0) || (De_vcnt == (I_v_res-1'b1))) && (Pout_de_dn[1] == 1'b1))
		Net_v_trig <= 1'b1;
	else
		Net_v_trig <= 1'b0;
end

assign Net_pos = {Net_v_trig,Net_h_trig};

always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Net_grid <= 24'd0;
	else if(Pout_de_dn[2] == 1'b1)
		case(Net_pos)
			2'b00	:	Net_grid	<=	BLACK  ;
			2'b01	:	Net_grid	<=	RED    ;
			2'b10	:	Net_grid	<=	RED    ;
			2'b11	:	Net_grid	<=	RED    ;
			default	:	Net_grid	<=	BLACK  ;
		endcase
	else
		Net_grid	<=	BLACK  ;
end

//---------------------------------------------------
//Gray  (kept for reference; no mode currently selects it)
//---------------------------------------------------
always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Gray <= 24'd0;
	else
		Gray <= {De_hcnt[7:0],De_hcnt[7:0],De_hcnt[7:0]};
end

always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		Gray_d1 <= 24'd0;
	else
		Gray_d1 <= Gray;
end

//---------------------------------------------------
// RGB triangle generator (OpenGL-style edge-function rasterization)
//---------------------------------------------------
// A static, centered, upward-pointing triangle with RED at the top
// vertex, GREEN at the bottom-left vertex and BLUE at the bottom-right
// vertex, smoothly interpolated (Gouraud-shaded) across the interior --
// the classic "hello triangle" look.
//
// Each pixel is classified with the same three edge-function (2D cross
// product) tests a GPU rasterizer uses, and its color is the exact
// barycentric blend of the three vertex colors.
//
// The vertices are laid out as a true equilateral triangle inscribed
// in a circle of radius Tri_size ("R"), apex pointing up:
//   V0 = ( 0            , -R    )  -> RED    (top)
//   V1 = (-R*sin(60 deg) , +R/2 )  -> GREEN  (bottom-left)
//   V2 = (+R*sin(60 deg) , +R/2 )  -> BLUE   (bottom-right)
// sin(60 deg) = sqrt(3)/2 is approximated as the fixed-point constant
// 887/1024 (relative error < 0.03%, i.e. sub-pixel for any realistic
// resolution).

// largest power-of-two <= val
function [11:0] f_pow2_floor;
	input [11:0] val;
	integer i;
	reg    found;
	begin
		found        = 1'b0;
		f_pow2_floor = 12'd1;
		for (i = 11; i >= 0; i = i - 1)
			if (!found && val[i]) begin
				f_pow2_floor = (12'd1 << i);
				found        = 1'b1;
			end
	end
endfunction

// static geometry, derived once from the frame size
wire [11:0] Tri_cx    = I_h_res >> 1;
wire [11:0] Tri_cy    = I_v_res >> 1;
wire [11:0] Tri_size  = f_pow2_floor(I_v_res >> 2);   // circumradius R, forced even (power of two) so R>>1 below is exact
wire [12:0] Tri_halfw = (Tri_size * 13'd887) >> 10;   // R * sin(60 deg) ~= R * sqrt(3)/2

wire [11:0] V0x = Tri_cx,             V0y = Tri_cy - Tri_size;       // top          - RED
wire [11:0] V1x = Tri_cx - Tri_halfw, V1y = Tri_cy + (Tri_size>>1);  // bottom-left  - GREEN
wire [11:0] V2x = Tri_cx + Tri_halfw, V2y = Tri_cy + (Tri_size>>1);  // bottom-right - BLUE

// signed pixel / vertex coordinates for the edge-function math
wire signed [13:0] Px  = $signed({2'b00, De_hcnt});
wire signed [13:0] Py  = $signed({2'b00, De_vcnt});
wire signed [13:0] Sx0 = $signed({2'b00, V0x}), Sy0 = $signed({2'b00, V0y});
wire signed [13:0] Sx1 = $signed({2'b00, V1x}), Sy1 = $signed({2'b00, V1y});
wire signed [13:0] Sx2 = $signed({2'b00, V2x}), Sy2 = $signed({2'b00, V2y});

// three edge functions (2x sub-triangle areas) -- same test an
// OpenGL/GPU rasterizer runs per pixel
wire signed [31:0] E0    = (Sx2-Sx1)*(Py-Sy1) - (Sy2-Sy1)*(Px-Sx1); // weight for V0 (red)
wire signed [31:0] E1    = (Sx0-Sx2)*(Py-Sy2) - (Sy0-Sy2)*(Px-Sx2); // weight for V1 (green)
wire signed [31:0] E2    = (Sx1-Sx0)*(Py-Sy0) - (Sy1-Sy0)*(Px-Sx0); // weight for V2 (blue)
wire signed [31:0] Area2 = (Sx1-Sx0)*(Sy2-Sy0) - (Sx2-Sx0)*(Sy1-Sy0);

// inside test: all three edge functions must share Area2's sign (winding-independent)
wire Tri_inside = Area2[31] ? (E0[31] & E1[31] & E2[31])
                             : (~E0[31] & ~E1[31] & ~E2[31]);

wire [31:0] E0a    = Area2[31] ? (~E0    + 32'd1) : E0[31:0];
wire [31:0] E1a    = Area2[31] ? (~E1    + 32'd1) : E1[31:0];
wire [31:0] E2a    = Area2[31] ? (~E2    + 32'd1) : E2[31:0];
wire [31:0] Area2a = Area2[31] ? (~Area2 + 32'd1) : Area2[31:0];  // |2*Area|, nonzero for this fixed geometry

// exact barycentric weights -> 8-bit vertex-color blend. Area2 carries
// a sqrt(3) factor now that the triangle is equilateral, so it is no
// longer a power of two -- this needs a genuine divide (synthesis
// infers a combinational divider) instead of the old exact shift.
wire [7:0] Tri_r = (E0a * 8'd255) / Area2a;
wire [7:0] Tri_g = (E1a * 8'd255) / Area2a;
wire [7:0] Tri_b = (E2a * 8'd255) / Area2a;

wire [23:0] Triangle_w = Tri_inside ? {Tri_b, Tri_g, Tri_r} : 24'h000000; //{B,G,R}

reg [23:0] Triangle;
always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if (!I_rst_n)
		Triangle <= 24'd0;
	else if (Pout_de_dn[2] == 1'b1)
		Triangle <= Triangle_w;
	else
		Triangle <= 24'd0;
end

//---------------------------------------------------
//Single color
//---------------------------------------------------
assign Single_color = {I_single_b,I_single_g,I_single_r};

//============================================================
assign Data_sel = (I_mode[2:0] == 3'b000) ? Color_bar	:
                  (I_mode[2:0] == 3'b001) ? Net_grid 	:
                  (I_mode[2:0] == 3'b010) ? Triangle 	:
                  (I_mode[2:0] == 3'b011) ? GREEN    	:  // single green
                  (I_mode[2:0] == 3'b100) ? BLUE     	:  // single blue
                  (I_mode[2:0] == 3'b101) ? RED      	:  // single red
                  (I_mode[2:0] == 3'b110) ? WHITE    	:
                                             BLACK    	;

//---------------------------------------------------
always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n) 
		Data_tmp <= 24'd0;
	else
		Data_tmp <= Data_sel;
end

assign O_data_r = Data_tmp[ 7: 0];
assign O_data_g = Data_tmp[15: 8];
assign O_data_b = Data_tmp[23:16];

endmodule