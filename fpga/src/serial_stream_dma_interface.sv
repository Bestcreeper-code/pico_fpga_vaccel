module qserial_interface #(
    parameter int WORD_BITS = 16,
) (
    input  logic clk_in,
    input  logic rst,

    input  logic is_rx,

    inout  logic [3:0] serial_data_bus,

    input  logic [WORD_BITS-1:0] tx_word,
    output logic [WORD_BITS-1:0] rx_word,
    output logic word_clk,
);

    localparam int CHUNKS = WORD_BITS / 4;
    localparam int CNT_W = $clog2(CHUNKS);


    logic [CNT_W-1:0] shift_count;

    logic [WORD_BITS-1:0] rx_shift;
    logic [WORD_BITS-1:0] tx_shift;

    always_ff @(posedge clk_in or negedge rst) begin
        if(shift_count < CHUNKS) begin
            if(is_rx) begin
                rx_shift <= {rx_shift, serial_data_bus};
                shift_count <= shift_count+1;
            end else begin
                //later
            end
        end else begin 
            rx_word = rx_shift;
            tx_shift = tx_word;
        end
    end


endmodule