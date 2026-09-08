/* verilator lint_off UNUSEDSIGNAL */

module ram_slave #( parameter int ADDR_WIDTH = 32, parameter 
    int DATA_WIDTH = 32, parameter int DEPTH = 256
)(
    input  logic                     ACLK,
    input  logic                     ARESETn,

    // ============================================================
    // Write Interface
    // ============================================================

    input  logic                     wr_en,
    input  logic [ADDR_WIDTH-1:0]     wr_addr,
    input  logic [DATA_WIDTH-1:0]     wr_data,
    input  logic [DATA_WIDTH/8-1:0]   wr_strb,

    output logic [1:0]                wr_resp,

    // ============================================================
    // Read Interface
    // ============================================================

    input  logic                     rd_en,
    input  logic [ADDR_WIDTH-1:0]     rd_addr,

    output logic [DATA_WIDTH-1:0]     rd_data,
    output logic [1:0]                rd_resp
);

/* verilator lint_on UNUSEDSIGNAL */

    localparam int ADDR_BITS  = $clog2(DEPTH);


    // ============================================================
    // RAM Storage
    // ============================================================

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];


    // ============================================================
    // Address to word index
    //
    // Four bytes per 32-bit word.
    //
    // Address:
    //   0x00 -> word 0
    //   0x04 -> word 1
    //   0x08 -> word 2
    //   ...
    // ============================================================

    logic [ADDR_BITS-1:0] wr_index;
    logic [ADDR_BITS-1:0] rd_index;

    assign wr_index = wr_addr[ADDR_BITS+1:2];
    assign rd_index = rd_addr[ADDR_BITS+1:2];


    // ============================================================
    // RAM Write
    // ============================================================

    always_ff @(posedge ACLK) begin

        if (!ARESETn) begin

            wr_resp <= 2'b00;

        end
        else begin

            if (wr_en) begin

                // ------------------------------------------------
                // Byte 0
                // ------------------------------------------------

                if (wr_strb[0])
                    mem[wr_index][7:0] <= wr_data[7:0];


                // ------------------------------------------------
                // Byte 1
                // ------------------------------------------------

                if (wr_strb[1])
                    mem[wr_index][15:8] <= wr_data[15:8];


                // ------------------------------------------------
                // Byte 2
                // ------------------------------------------------

                if (wr_strb[2])
                    mem[wr_index][23:16] <= wr_data[23:16];


                // ------------------------------------------------
                // Byte 3
                // ------------------------------------------------

                if (wr_strb[3])
                    mem[wr_index][31:24] <= wr_data[31:24];


                // ------------------------------------------------
                // Successful write
                // ------------------------------------------------

                wr_resp <= 2'b00;

            end

        end

    end


    // ============================================================
    // RAM Read
    // ============================================================

    always_ff @(posedge ACLK) begin

        if (!ARESETn) begin

            rd_data <= '0;
            rd_resp <= 2'b00;

        end
        else begin

            if (rd_en) begin

                rd_data <= mem[rd_index];
                rd_resp <= 2'b00;

            end

        end

    end


endmodule
