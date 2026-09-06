module axi4_lite_master #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input  logic                  ACLK,
    input  logic                  ARESETn,

    // ============================================================
    // Simple user-side write interface
    // ============================================================

    input  logic [ADDR_WIDTH-1:0] write_addr,
    input  logic [DATA_WIDTH-1:0] write_data,
    input  logic [DATA_WIDTH/8-1:0] write_strb,
    input  logic                  write_valid,
    output logic                  write_ready,

    output logic [1:0]            write_resp,
    output logic                  write_resp_valid,

    // ============================================================
    // Simple user-side read interface
    // ============================================================

    input  logic [ADDR_WIDTH-1:0] read_addr,
    input  logic                  read_valid,
    output logic                  read_ready,

    output logic [DATA_WIDTH-1:0] read_data,
    output logic [1:0]            read_resp,
    output logic                  read_resp_valid,

    // ============================================================
    // AXI4-Lite master interface
    // ============================================================

    output logic [ADDR_WIDTH-1:0]  M_AWADDR,
    output logic                   M_AWVALID,
    input  logic                   M_AWREADY,

    output logic [DATA_WIDTH-1:0]  M_WDATA,
    output logic [DATA_WIDTH/8-1:0] M_WSTRB,
    output logic                   M_WVALID,
    input  logic                   M_WREADY,

    input  logic [1:0]             M_BRESP,
    input  logic                    M_BVALID,
    output logic                    M_BREADY,

    output logic [ADDR_WIDTH-1:0]  M_ARADDR,
    output logic                   M_ARVALID,
    input  logic                   M_ARREADY,

    input  logic [DATA_WIDTH-1:0]  M_RDATA,
    input  logic [1:0]             M_RRESP,
    input  logic                    M_RVALID,
    output logic                    M_RREADY
);

    localparam int STRB_WIDTH = DATA_WIDTH / 8;


    // ============================================================
    // Write FSM
    // ============================================================

    typedef enum logic [2:0] {
        WR_IDLE,
        WR_SEND,
        WR_RESP
    } write_state_t;

    write_state_t write_state;


    // ============================================================
    // Read FSM
    // ============================================================

    typedef enum logic [1:0] {
        RD_IDLE,
        RD_SEND,
        RD_DATA
    } read_state_t;

    read_state_t read_state;


    // ============================================================
    // Write transaction registers
    // ============================================================

    logic [ADDR_WIDTH-1:0]  write_addr_reg;
    logic [DATA_WIDTH-1:0]  write_data_reg;
    logic [STRB_WIDTH-1:0]  write_strb_reg;

    logic aw_done;
    logic w_done;


    // ============================================================
    // Read transaction register
    // ============================================================

    logic [ADDR_WIDTH-1:0] read_addr_reg;


    // ============================================================
    // Write FSM
    // ============================================================

    always_ff @(posedge ACLK) begin

        if (!ARESETn) begin

            write_state      <= WR_IDLE;

            write_addr_reg   <= '0;
            write_data_reg   <= '0;
            write_strb_reg   <= '0;

            aw_done          <= 1'b0;
            w_done           <= 1'b0;

            write_resp       <= 2'b00;
            write_resp_valid <= 1'b0;

        end
        else begin

            write_resp_valid <= 1'b0;

            case (write_state)

                WR_IDLE: begin

                    aw_done <= 1'b0;
                    w_done  <= 1'b0;

                    if (write_valid && write_ready) begin

                        write_addr_reg <= write_addr;
                        write_data_reg <= write_data;
                        write_strb_reg <= write_strb;

                        write_state <= WR_SEND;

                    end

                end


                WR_SEND: begin

                    if (M_AWVALID && M_AWREADY)
                        aw_done <= 1'b1;

                    if (M_WVALID && M_WREADY)
                        w_done <= 1'b1;

                    if ((aw_done || (M_AWVALID && M_AWREADY)) &&
                        (w_done  || (M_WVALID  && M_WREADY))) begin

                        write_state <= WR_RESP;

                    end

                end


                WR_RESP: begin

                    if (M_BVALID && M_BREADY) begin

                        write_resp       <= M_BRESP;
                        write_resp_valid <= 1'b1;

                        write_state <= WR_IDLE;

                    end

                end


                default: begin
                    write_state <= WR_IDLE;
                end

            endcase

        end

    end


    // ============================================================
    // Read FSM
    // ============================================================

    always_ff @(posedge ACLK) begin

        if (!ARESETn) begin

            read_state      <= RD_IDLE;

            read_addr_reg   <= '0;

            read_data       <= '0;
            read_resp       <= 2'b00;
            read_resp_valid <= 1'b0;

        end
        else begin

            read_resp_valid <= 1'b0;

            case (read_state)

                RD_IDLE: begin

                    if (read_valid && read_ready) begin

                        read_addr_reg <= read_addr;

                        read_state <= RD_SEND;

                    end

                end


                RD_SEND: begin

                    if (M_ARVALID && M_ARREADY) begin
                        read_state <= RD_DATA;
                    end

                end


                RD_DATA: begin

                    if (M_RVALID && M_RREADY) begin

                        read_data       <= M_RDATA;
                        read_resp       <= M_RRESP;
                        read_resp_valid <= 1'b1;

                        read_state <= RD_IDLE;

                    end

                end


                default: begin
                    read_state <= RD_IDLE;
                end

            endcase

        end

    end


    // ============================================================
    // Write user-side ready
    // ============================================================

    assign write_ready =
        (write_state == WR_IDLE);


    // ============================================================
    // Read user-side ready
    // ============================================================

    assign read_ready =
        (read_state == RD_IDLE);


    // ============================================================
    // AXI Write Address Channel
    // ============================================================

    assign M_AWADDR  = write_addr_reg;

    assign M_AWVALID =
        (write_state == WR_SEND) && !aw_done;


    // ============================================================
    // AXI Write Data Channel
    // ============================================================

    assign M_WDATA = write_data_reg;

    assign M_WSTRB = write_strb_reg;

    assign M_WVALID =
        (write_state == WR_SEND) && !w_done;


    // ============================================================
    // AXI Write Response Channel
    // ============================================================

    assign M_BREADY =
        (write_state == WR_RESP);


    // ============================================================
    // AXI Read Address Channel
    // ============================================================

    assign M_ARADDR = read_addr_reg;

    assign M_ARVALID =
        (read_state == RD_SEND);


    // ============================================================
    // AXI Read Data Channel
    // ============================================================

    assign M_RREADY =
        (read_state == RD_DATA);


endmodule
