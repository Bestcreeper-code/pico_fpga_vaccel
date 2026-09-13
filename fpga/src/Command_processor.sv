typedef struct packed {
    logic [7:0]  opcode;
    logic [7:0]  args;
    logic [15:0] length;
} command_header;

enum logic [7:0] {
    VACCEL_CMD_SET_STATUS_LED               = 'hDB,
    VACCEL_CMD_WRITE_ADDR                   = 'hF0,
    VACCEL_CMD_READ_LOHALF_BYTEADDR_DBUS    = 'hF1
} vaccel_opcodes;

module Command_Processor #(
    parameter int WORD_BITS = 32
)(
    input  logic sys_clk,
    input logic rst_n,

    input  logic new_word_present_clk,
    input  logic [WORD_BITS-1:0] rx_data,
    output logic [WORD_BITS-1:0] tx_data,

    output logic dbus_we,
    output logic [31:0] dbus_addr,
    inout  logic [31:0] dbus_data,
    input  logic dbus_ok,

    output logic irq,
    output logic [5:0] leds
);
// how many cycles after asserting fifo_rden until fifo_rd_data is valid
localparam int FIFO_RD_LATENCY = 2;  // bump to 2 or 3 if your FIFO IP needs it
    //Command & Data FIFO

    logic fifo_rden;
    logic [31:0] fifo_rd_data;
    logic fifo_empty;
    logic fifo_full;
    
    bram_512_32b_fifo your_instance_name(
		.Data(rx_data), //input [31:0] Data
		.WrClk(new_word_present_clk), //input WrClk
		.RdClk(sys_clk), //input RdClk
		.WrEn(1'b1), //input WrEn
		.RdEn(fifo_rden), //input RdEn
		.Q(fifo_rd_data), //output [31:0] Q
		.Empty(fifo_empty), //output Empty
		.Full(fifo_full) //output Full
	);






    //Main State machine

    logic [WORD_BITS-1:0] command_word;
    command_header command_word_hdr;
    assign command_word_hdr = command_header'(command_word);

    // sm states
    typedef enum logic [1:0] {
        ST_FETCH,
        ST_RUNNING,
        ST_BUS_WRITE,
        ST_BUS_READ
    } cmd_state_t;

    cmd_state_t state;

    logic [31:0] sm_regs[4];
    
    // sm external access bus
    logic [31:0] bus_addr_r;
    logic [31:0] bus_wdata_r;
    logic [31:0] bus_rdata_r;

    
    logic read_reply_pending;

    assign dbus_data = (state == ST_BUS_WRITE) ? bus_wdata_r : 32'bz;

    
    `define BUS_WRITE(ADDR, DATA) begin \
        bus_addr_r  <= (ADDR);          \
        bus_wdata_r <= (DATA);          \
        state       <= ST_BUS_WRITE;    \
    end

    `define BUS_READ(ADDR) begin \
        bus_addr_r <= (ADDR);     \
        state      <= ST_BUS_READ; \
    end

    `define POP_ENABLE() fifo_rden <= 1'b1
    `define POP_DISABLE() fifo_rden <= 1'b0
    `define POP_REG(REG) REG <= fifo_rd_data
    `define POP_REG_SYNC(REG) REG = fifo_rd_data

    always_ff @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            irq     <= '0;
            dbus_we <= '0;
            state <= ST_FETCH;
            fifo_rden <= '0; 
            
            //reset regs
            sm_regs[0]<='0;
            sm_regs[1]<='0;
            sm_regs[2]<='0;
            sm_regs[3]<='0;
        end else begin
            case (state)
                ST_FETCH: begin
                    // pulse fifo_rden for one cycle if data is waiting
                    if (!fifo_rden && sm_regs[1] == '0) begin
                        if (!fifo_empty) begin
                            `POP_ENABLE;
                            sm_regs[0] <= '0;
                        end
                    end
                    // clear rd en and wait.
                    else if (fifo_rden) begin
                        `POP_DISABLE;
                        sm_regs[1] <= 1'b1;
                        sm_regs[0] <= '0;
                    end
                    // wait remaining read latency
                    else begin
                        if (sm_regs[0] >= FIFO_RD_LATENCY - 1) begin
                            `POP_REG(command_word);
                            sm_regs[0] <= '0;
                            sm_regs[1] <= '0;
                            state <= ST_RUNNING;
                        end else begin
                            sm_regs[0] <= sm_regs[0] + 1'b1;
                        end
                    end
                end


                ST_RUNNING: begin
                    if (command_word != '0) begin
                        case (command_word_hdr.opcode)

                            VACCEL_CMD_SET_STATUS_LED: begin
                                leds         <= command_word_hdr.args[5:0];
                                command_word <= '0;
                                state        <= ST_FETCH;
                            end

                            VACCEL_CMD_WRITE_ADDR: begin

                                // We returned from ST_BUS_WRITE - the write is complete.
                                if (sm_regs[1] == 1'b1) begin
                                    command_word <= '0;

                                    sm_regs[0] <= '0;
                                    sm_regs[1] <= '0;
                                    sm_regs[2] <= '0;
                                    sm_regs[3] <= '0;

                                    state <= ST_FETCH;
                                end

                                // Phase 1: latch the address from the header, then pulse fifo_rden
                                // for exactly one cycle to start fetching the data word.
                                else if (!fifo_rden && sm_regs[2] == '0) begin
                                    if (!fifo_empty) begin
                                        bus_addr_r <= {command_word_hdr.args,
                                                       command_word_hdr.length};

                                        `POP_ENABLE;
                                        sm_regs[0] <= '0;
                                    end
                                end

                                // Phase 2: fifo_rden was high for exactly one cycle; drop it and
                                // start waiting out the remaining read latency.
                                else if (fifo_rden) begin
                                    `POP_DISABLE;
                                    sm_regs[2] <= 1'b1;
                                    sm_regs[0] <= '0;
                                end

                                // Phase 3: waiting for fifo_rd_data to become valid; sample once.
                                else begin
                                    if (sm_regs[0] >= FIFO_RD_LATENCY - 1) begin
                                        bus_wdata_r <= fifo_rd_data;

                                        sm_regs[0] <= '0;
                                        sm_regs[2] <= '0;
                                        sm_regs[1] <= 1'b1;

                                        state <= ST_BUS_WRITE;
                                    end
                                    else begin
                                        sm_regs[0] <= sm_regs[0] + 1'b1;
                                    end
                                end
                            end

                            default: begin
                                irq          <= '1;
                                tx_data      <= 'hBAD1;
                                command_word <= '0;
                                state        <= ST_FETCH;
                            end
                        endcase
                    end else begin
                        state <= ST_FETCH;//deadlock prevention
                    end
                end

                ST_BUS_WRITE: begin
                    dbus_we   <= '1;
                    dbus_addr <= bus_addr_r;
                    if (dbus_ok) begin
                        dbus_we      <= '0;
                        state        <= ST_RUNNING;
                    end
                end

                ST_BUS_READ: begin
                    dbus_we   <= '0;
                    dbus_addr <= bus_addr_r;
                    if (dbus_ok) begin
                        bus_rdata_r <= dbus_data;
                        if (read_reply_pending) begin
                            tx_data            <= dbus_data;  // same-cycle value, same source as bus_rdata_r
                            irq                <= 1'b1;
                            read_reply_pending <= 1'b0;
                        end
                        state        <= ST_RUNNING;
                    end
                end

            endcase
        end
    end

endmodule