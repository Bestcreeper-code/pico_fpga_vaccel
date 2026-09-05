typedef struct packed {
    logic [7:0]  opcode;
    logic [7:0]  args;
    logic [15:0] length;
} command_header;

enum logic [7:0] {
    VACCEL_CMD_SET_STATUS_LED = 'hDB
} vaccel_opcodes;

module Command_Processor #(
    parameter int WORD_BITS = 32
)(
    input  logic sys_clk,
    input  logic new_word_present,
    input  logic [WORD_BITS-1:0] rx_data,
    output logic [WORD_BITS-1:0] tx_data,
    output logic irq,
    output logic [5:0] leds
);
    logic [WORD_BITS-1:0] temp_word;
    command_header temp_word_hdr;
    assign temp_word_hdr = command_header'(temp_word);

    always_ff @(posedge sys_clk) begin
        irq <= '0;
        if (new_word_present) begin
            temp_word <= rx_data;
        end
        if (temp_word != '0) begin
            case (temp_word_hdr.opcode)

                VACCEL_CMD_SET_STATUS_LED: leds <= temp_word_hdr.args[5:0];

                default: begin
                    irq     <= '1;
                    tx_data <= 'hBAD1;
                end
            endcase
        end
    end
endmodule