package axi4_lite_pkg;

    // ============================================================
    // AXI4-Lite Configuration
    // ============================================================

    parameter int ADDR_WIDTH = 32;
    parameter int DATA_WIDTH = 32;
    parameter int STRB_WIDTH = DATA_WIDTH / 8;


    // ============================================================
    // AXI4-Lite Response Codes
    // ============================================================

    typedef enum logic [1:0] {

        AXI_RESP_OKAY   = 2'b00,
        AXI_RESP_EXOKAY = 2'b01,
        AXI_RESP_SLVERR = 2'b10,
        AXI_RESP_DECERR = 2'b11

    } axi_resp_t;


    // ============================================================
    // AXI4-Lite Response Code Constants
    // ============================================================

    localparam logic [1:0] AXI_OKAY   = 2'b00;
    localparam logic [1:0] AXI_EXOKAY = 2'b01;
    localparam logic [1:0] AXI_SLVERR = 2'b10;
    localparam logic [1:0] AXI_DECERR = 2'b11;


endpackage
