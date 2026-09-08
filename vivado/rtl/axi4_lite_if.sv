interface axi4_lite_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input logic ACLK,
    input logic ARESETn
);

    // ============================================================
    // AXI4-Lite Write Address Channel
    // ============================================================

    logic [ADDR_WIDTH-1:0] AWADDR;
    logic                  AWVALID;
    logic                  AWREADY;


    // ============================================================
    // AXI4-Lite Write Data Channel
    // ============================================================

    logic [DATA_WIDTH-1:0] WDATA;
    logic [DATA_WIDTH/8-1:0] WSTRB;
    logic                    WVALID;
    logic                    WREADY;


    // ============================================================
    // AXI4-Lite Write Response Channel
    // ============================================================

    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;


    // ============================================================
    // AXI4-Lite Read Address Channel
    // ============================================================

    logic [ADDR_WIDTH-1:0] ARADDR;
    logic                  ARVALID;
    logic                  ARREADY;


    // ============================================================
    // AXI4-Lite Read Data Channel
    // ============================================================

    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RVALID;
    logic                  RREADY;


    // ============================================================
    // AXI4-Lite Master Modport
    // ============================================================

    modport master (

        input  ACLK,
        input  ARESETn,

        // Write Address
        output AWADDR,
        output AWVALID,
        input  AWREADY,

        // Write Data
        output WDATA,
        output WSTRB,
        output WVALID,
        input  WREADY,

        // Write Response
        input  BRESP,
        input  BVALID,
        output BREADY,

        // Read Address
        output ARADDR,
        output ARVALID,
        input  ARREADY,

        // Read Data
        input  RDATA,
        input  RRESP,
        input  RVALID,
        output RREADY

    );


    // ============================================================
    // AXI4-Lite Slave Modport
    // ============================================================

    modport slave (

        input  ACLK,
        input  ARESETn,

        // Write Address
        input  AWADDR,
        input  AWVALID,
        output AWREADY,

        // Write Data
        input  WDATA,
        input  WSTRB,
        input  WVALID,
        output WREADY,

        // Write Response
        output BRESP,
        output BVALID,
        input  BREADY,

        // Read Address
        input  ARADDR,
        input  ARVALID,
        output ARREADY,

        // Read Data
        output RDATA,
        output RRESP,
        output RVALID,
        input  RREADY

    );

endinterface
