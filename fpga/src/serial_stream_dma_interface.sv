module serial_interface #(
    parameter int WORD_BITS        = 16,
    parameter int ADDRESS_BUS_SIZE = 12
) (
    input  logic clk_in,
    input  logic rst,

    inout  logic [3:0] serial_data,

    input  logic [WORD_BITS-1:0] tx_word,
    output logic [WORD_BITS-1:0] rx_word,
    output logic word_clk,
    
    output logic [1:0] leds,
);

    localparam int CHUNK_BITS = 2;
    localparam int CHUNKS = WORD_BITS / CHUNK_BITS;
    localparam int CNT_W = $clog2(CHUNKS);

    assign data_bus_clk = clk_in;
//debug
    logic [23:0] clk_div;

    always_ff @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            clk_div <= '0;
        end else begin
            clk_div <= clk_div + 1'b1;
        end
    end

    assign leds[0] = clk_div[20];
    
    logic sync_seen;

always_ff @(posedge clk_in or negedge rst) begin
    if (!rst) begin
        sync_seen <= 1'b0;
    end else begin
        if (sync_in)
            sync_seen <= 1'b1;
    end
end

assign leds[1] = sync_seen;








    logic [CNT_W-1:0] count;

    logic [WORD_BITS-1:0] rx_shift;
    logic [WORD_BITS-1:0] tx_shift;

    always_ff @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            count        <= '0;
            rx_shift     <= '0;
            tx_shift     <= '0;

            rx_out       <= '0;

            we           <= 1'b0;
            data_bus_out <= '0;
            addr_bus     <= '0;

        end else begin

            we <= 1'b0;


            if (sync_in) begin

                count <= CNT_W'(1);
                rx_shift <= {{(WORD_BITS-CHUNK_BITS){1'b0}}, tx_in};
                tx_shift <= {rx_tx_word[WORD_BITS-CHUNK_BITS-1:0], {CHUNK_BITS{1'b0}}};

                rx_out <= rx_tx_word[WORD_BITS-1 -: CHUNK_BITS];


            end else begin

                rx_shift <= {rx_shift[WORD_BITS-CHUNK_BITS-1:0],
                             tx_in};

                rx_out <= tx_shift[WORD_BITS-1 -: CHUNK_BITS];

                tx_shift <= {tx_shift[WORD_BITS-CHUNK_BITS-1:0],
                             {CHUNK_BITS{1'b0}}};


                if (count == CHUNKS-1) begin

                    data_bus_out <= {rx_shift[WORD_BITS-CHUNK_BITS-1:0],
                                     tx_in};

                    addr_bus <= addr_bus + 1'b1;

                    we <= 1'b1;

                    count <= '0;

                end else begin
                    count <= count + 1'b1;
                end

            end
        end
    end

endmodule