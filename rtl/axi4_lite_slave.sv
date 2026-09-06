module axi4_lite_slave #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input  logic                    ACLK,
    input  logic                    ARESETn,

    // ============================================================
    // AXI4-Lite Write Address Channel
    // ============================================================

    input  logic [ADDR_WIDTH-1:0]    S_AWADDR,
    input  logic                     S_AWVALID,
    output logic                     S_AWREADY,

    // ============================================================
    // AXI4-Lite Write Data Channel
    // ============================================================

    input  logic [DATA_WIDTH-1:0]    S_WDATA,
    input  logic [DATA_WIDTH/8-1:0]  S_WSTRB,
    input  logic                     S_WVALID,
    output logic                     S_WREADY,

    // ============================================================
    // AXI4-Lite Write Response Channel
    // ============================================================

    output logic [1:0]               S_BRESP,
    output logic                     S_BVALID,
    input  logic                     S_BREADY,

    // ============================================================
    // AXI4-Lite Read Address Channel
    // ============================================================

    input  logic [ADDR_WIDTH-1:0]    S_ARADDR,
    input  logic                     S_ARVALID,
    output logic                     S_ARREADY,

    // ============================================================
    // AXI4-Lite Read Data Channel
    // ============================================================

    output logic [DATA_WIDTH-1:0]    S_RDATA,
    output logic [1:0]               S_RRESP,
    output logic                     S_RVALID,
    input  logic                     S_RREADY,

    // ============================================================
    // Backend Write Interface
    // ============================================================

    output logic                     wr_en,
    output logic [ADDR_WIDTH-1:0]    wr_addr,
    output logic [DATA_WIDTH-1:0]    wr_data,
    output logic [DATA_WIDTH/8-1:0]  wr_strb,

    input  logic [1:0]               wr_resp,

    // ============================================================
    // Backend Read Interface
    // ============================================================

    output logic                     rd_en,
    output logic [ADDR_WIDTH-1:0]    rd_addr,

    input  logic [DATA_WIDTH-1:0]    rd_data,
    input  logic [1:0]               rd_resp
);


    localparam int STRB_WIDTH = DATA_WIDTH / 8;


    // ============================================================
    // Write-side registers
    // ============================================================

    logic [ADDR_WIDTH-1:0]   awaddr_reg;
    logic [DATA_WIDTH-1:0]   wdata_reg;
    logic [STRB_WIDTH-1:0]   wstrb_reg;

    logic                    aw_received;
    logic                    w_received;


    // ============================================================
    // Read-side register
    // ============================================================

    logic                    read_active;


    // ============================================================
    // AXI Write Address READY
    //
    // Accept a new address when:
    //   - no address is currently stored
    //   - no write response is pending
    // ============================================================

    always_comb begin

        S_AWREADY = !aw_received && !S_BVALID;

    end


    // ============================================================
    // AXI Write Data READY
    //
    // Address and data channels are independent in AXI4-Lite.
    // Therefore W can arrive before AW.
    // ============================================================

    always_comb begin

        S_WREADY = !w_received && !S_BVALID;

    end


    // ============================================================
    // AXI Read Address READY
    // ============================================================

    always_comb begin

        S_ARREADY = !read_active && !S_RVALID;

    end


    // ============================================================
    // Backend Write Enable
    //
    // A write occurs when both AW and W have been received.
    // ============================================================

    always_comb begin

        wr_en   = aw_received && w_received && !S_BVALID;

        wr_addr = awaddr_reg;
        wr_data = wdata_reg;
        wr_strb = wstrb_reg;

    end


    // ============================================================
    // Backend Read Enable
    //
    // A read is generated when the AXI read address handshakes.
    // ============================================================

    always_comb begin

        rd_en   = S_ARVALID && S_ARREADY;
        rd_addr = S_ARADDR;

    end


    // ============================================================
    // Write and Read Sequential Logic
    // ============================================================

    always_ff @(posedge ACLK) begin

        if (!ARESETn) begin

            awaddr_reg <= '0;
            wdata_reg  <= '0;
            wstrb_reg  <= '0;

            aw_received <= 1'b0;
            w_received  <= 1'b0;

            S_BRESP  <= 2'b00;
            S_BVALID <= 1'b0;

            S_RDATA  <= '0;
            S_RRESP  <= 2'b00;
            S_RVALID <= 1'b0;

            read_active <= 1'b0;

        end
        else begin

            // ====================================================
            // Write Address Capture
            // ====================================================

            if (S_AWVALID && S_AWREADY) begin

                awaddr_reg  <= S_AWADDR;
                aw_received <= 1'b1;

            end


            // ====================================================
            // Write Data Capture
            // ====================================================

            if (S_WVALID && S_WREADY) begin

                wdata_reg  <= S_WDATA;
                wstrb_reg  <= S_WSTRB;
                w_received <= 1'b1;

            end


            // ====================================================
            // Generate Write Response
            //
            // Once both address and data are captured, the backend
            // write is considered accepted and its response is
            // returned to the AXI master.
            // ====================================================

            if (wr_en) begin

                S_BRESP  <= wr_resp;
                S_BVALID <= 1'b1;

            end


            // ====================================================
            // Complete Write Response
            // ====================================================

            if (S_BVALID && S_BREADY) begin

                S_BVALID <= 1'b0;

                aw_received <= 1'b0;
                w_received  <= 1'b0;

            end


            // ====================================================
            // Read Address Handshake
            // ====================================================

            if (S_ARVALID && S_ARREADY) begin

                read_active <= 1'b1;

                S_RDATA <= rd_data;
                S_RRESP <= rd_resp;

                S_RVALID <= 1'b1;

            end


            // ====================================================
            // Complete Read Response
            // ====================================================

            if (S_RVALID && S_RREADY) begin

                S_RVALID <= 1'b0;

                read_active <= 1'b0;

            end

        end

    end

endmodule
