typedef struct packed {
    logic [7:0]  opcode;
    logic [7:0]  args;
    logic [15:0] length;
} command_header;

enum logic [7:0] {
    VACCEL_CMD_SET_STATUS_LED = 'hDB,
    VACCEL_CMD_WRITE_LOHALF_BYTEADDR_DBUS = 'hF0,
    VACCEL_CMD_READ_LOHALF_BYTEADDR_DBUS = 'hF2
} vaccel_opcodes;

module Command_Processor #(
    parameter int WORD_BITS = 32
)(
    //engine clock
    input  logic sys_clk,
    input  logic rst_n,              // <-- added
    //serial interface
    input  logic new_word_present,
    input  logic [WORD_BITS-1:0] rx_data,
    output logic [WORD_BITS-1:0] tx_data,
    //data bus
    output logic dbus_we,
    output logic [31:0] dbus_addr,
    inout  logic [31:0] dbus_data,
    input  logic dbus_ok,
    //misc
    output logic irq,
    output logic [5:0] leds
);
    logic [WORD_BITS-1:0] command_word;
    command_header command_word_hdr;
    assign command_word_hdr = command_header'(command_word);

    typedef enum logic [1:0] {
        ST_RUNNING,
        ST_BUS_WRITE,
        ST_BUS_READ
    } cmd_state_t;
    cmd_state_t state;

    logic [31:0] bus_addr_r;
    logic [31:0] bus_wdata_r;
    logic [31:0] bus_rdata_r;

    
    assign dbus_addr = bus_addr_r;
    assign dbus_data = (state == ST_BUS_WRITE) ? bus_wdata_r : 32'bz;

    `define BUS_WRITE(ADDR, DATA)  \
    bus_addr_r   <= (ADDR);    \
    bus_wdata_r  <= (DATA);    \
    dbus_we      <= '1;        \
    state        <= ST_BUS_WRITE

    `define BUS_READ(ADDR)     \
        bus_addr_r  <= (ADDR); \
        state       <= ST_BUS_READ

    int unsigned sm_regs[3:0];

    always_ff @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            irq          <= '0;
            dbus_we      <= '0;
            leds         <= '0;
            tx_data      <= '0;
            command_word <= '0;
            bus_addr_r   <= '0;
            bus_wdata_r  <= '0;
            bus_rdata_r  <= '0;
            sm_regs[0] <= '0;
            sm_regs[1] <= '0;
            sm_regs[2] <= '0;
            sm_regs[3] <= '0;
            state        <= ST_RUNNING;
        end else begin
            irq     <= '0;
            dbus_we <= '0;

            if (new_word_present && command_word == '0) begin
                command_word <= rx_data;
            end

            case (state)
                ST_RUNNING: begin
                    if (command_word != '0) begin
                        case (command_word_hdr.opcode)







                            VACCEL_CMD_SET_STATUS_LED: begin
                                leds         <= command_word_hdr.args[5:0];
                                command_word <= '0;
                            end






                            VACCEL_CMD_WRITE_LOHALF_BYTEADDR_DBUS: begin
                                if (sm_regs[0] == 0) begin
                                    `BUS_WRITE(command_word_hdr.args, command_word_hdr.length);
                                    sm_regs[0] <= 1;
                                end else begin
                                    irq          <= '1;
                                    command_word <= '0;
                                    sm_regs[0] <= '0;
                                end
                            end




                            VACCEL_CMD_READ_LOHALF_BYTEADDR_DBUS: begin
                                if (sm_regs[0] == 0) begin
                                    `BUS_READ(command_word_hdr.args);
                                    sm_regs[0] <= 1;
                                end else begin
                                    tx_data      <= bus_rdata_r;
                                    irq          <= '1;
                                    command_word <= '0;
                                    sm_regs[0] <= '0;
                                end
                            end






                            default: begin
                                irq          <= '1;
                                tx_data      <= 'hBAD1;
                                command_word <= '0;
                            end
                        endcase
                    end
                end

                ST_BUS_WRITE: begin
                    if (dbus_ok) begin
                        state <= ST_RUNNING;
                    end
                end

                ST_BUS_READ: begin
                    if (dbus_ok) begin
                        bus_rdata_r  <= dbus_data;
                        command_word <= '0;
                        state        <= ST_RUNNING;
                    end
                end

                default: state <= ST_RUNNING;
            endcase
        end
    end
endmodule