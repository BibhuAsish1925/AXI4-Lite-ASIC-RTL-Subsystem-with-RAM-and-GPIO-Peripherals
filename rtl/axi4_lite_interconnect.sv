module axi4_lite_interconnect #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input logic ACLK,
    input logic ARESETn,

    // ============================================================
    // AXI4-Lite master side
    // ============================================================

    input  logic [ADDR_WIDTH-1:0]   M_AWADDR,
    input logic                     M_AWVALID,
    output logic                    M_AWREADY,

    input logic [DATA_WIDTH-1:0]   M_WDATA,
    input logic [DATA_WIDTH/8-1:0] M_WSTRB,
    input logic                     M_WVALID,
    output logic                    M_WREADY,

    output logic [1:0]              M_BRESP,
    output logic                    M_BVALID,
    input logic                     M_BREADY,

    input logic [ADDR_WIDTH-1:0]   M_ARADDR,
    input logic                     M_ARVALID,
    output logic                    M_ARREADY,

    output logic [DATA_WIDTH-1:0]   M_RDATA,
    output logic [1:0]              M_RRESP,
    output logic                    M_RVALID,
    input logic                     M_RREADY,


    // ============================================================
    // RAM slave side
    // ============================================================

    output logic                    RAM_wr_en,
    output logic [ADDR_WIDTH-1:0]   RAM_wr_addr,
    output logic [DATA_WIDTH-1:0]   RAM_wr_data,
    output logic [DATA_WIDTH/8-1:0] RAM_wr_strb,
    input logic [1:0]               RAM_wr_resp,

    output logic                    RAM_rd_en,
    output logic [ADDR_WIDTH-1:0]   RAM_rd_addr,
    input logic [DATA_WIDTH-1:0]    RAM_rd_data,
    input logic [1:0]               RAM_rd_resp,


    // ============================================================
    // GPIO slave side
    // ============================================================

    output logic                    GPIO_wr_en,
    output logic [ADDR_WIDTH-1:0]   GPIO_wr_addr,
    output logic [DATA_WIDTH-1:0]   GPIO_wr_data,
    output logic [DATA_WIDTH/8-1:0] GPIO_wr_strb,
    input logic [1:0]               GPIO_wr_resp,

    output logic                    GPIO_rd_en,
    output logic [ADDR_WIDTH-1:0]   GPIO_rd_addr,
    input logic [DATA_WIDTH-1:0]    GPIO_rd_data,
    input logic [1:0]               GPIO_rd_resp
);

    localparam logic [ADDR_WIDTH-1:0] RAM_BASE  = 32'h0000_0000;
    localparam logic [ADDR_WIDTH-1:0] RAM_LAST  = 32'h0000_03FF;

    localparam logic [ADDR_WIDTH-1:0] GPIO_BASE = 32'h0000_1000;
    localparam logic [ADDR_WIDTH-1:0] GPIO_LAST = 32'h0000_10FF;

    localparam logic [1:0] AXI_OKAY   = 2'b00;
    localparam logic [1:0] AXI_DECERR = 2'b11;


    logic write_ram_sel;
    logic write_gpio_sel;
    logic write_decerr;

    logic read_ram_sel;
    logic read_gpio_sel;
    logic read_decerr;


    // ============================================================
    // Write address decoder
    // ============================================================

    always_comb begin

        write_ram_sel  = 1'b0;
        write_gpio_sel = 1'b0;
        write_decerr   = 1'b0;

        if ((M_AWADDR >= RAM_BASE) &&
            (M_AWADDR <= RAM_LAST)) begin

            write_ram_sel = 1'b1;

        end
        else if ((M_AWADDR >= GPIO_BASE) &&
                 (M_AWADDR <= GPIO_LAST)) begin

            write_gpio_sel = 1'b1;

        end
        else begin

            write_decerr = 1'b1;

        end

    end


    // ============================================================
    // Read address decoder
    // ============================================================

    always_comb begin

        read_ram_sel  = 1'b0;
        read_gpio_sel = 1'b0;
        read_decerr   = 1'b0;

        if ((M_ARADDR >= RAM_BASE) &&
            (M_ARADDR <= RAM_LAST)) begin

            read_ram_sel = 1'b1;

        end
        else if ((M_ARADDR >= GPIO_BASE) &&
                 (M_ARADDR <= GPIO_LAST)) begin

            read_gpio_sel = 1'b1;

        end
        else begin

            read_decerr = 1'b1;

        end

    end


    // ============================================================
    // Write routing
    // ============================================================

    always_comb begin

        M_AWREADY = 1'b0;
        M_WREADY  = 1'b0;

        RAM_wr_en   = 1'b0;
        RAM_wr_addr = M_AWADDR;
        RAM_wr_data = M_WDATA;
        RAM_wr_strb = M_WSTRB;

        GPIO_wr_en   = 1'b0;
        GPIO_wr_addr = M_AWADDR;
        GPIO_wr_data = M_WDATA;
        GPIO_wr_strb = M_WSTRB;


        if (write_ram_sel) begin

            M_AWREADY = 1'b1;
            M_WREADY  = 1'b1;

            RAM_wr_en = M_AWVALID && M_WVALID;

        end
        else if (write_gpio_sel) begin

            M_AWREADY = 1'b1;
            M_WREADY  = 1'b1;

            GPIO_wr_en = M_AWVALID && M_WVALID;

        end

    end


    // ============================================================
    // Write response routing
    // ============================================================

    always_comb begin

        M_BVALID = 1'b0;
        M_BRESP  = AXI_DECERR;

        if (write_ram_sel) begin

            M_BVALID = RAM_wr_en;
            M_BRESP  = RAM_wr_resp;

        end
        else if (write_gpio_sel) begin

            M_BVALID = GPIO_wr_en;
            M_BRESP  = GPIO_wr_resp;

        end
        else if (write_decerr) begin

            M_BVALID = M_AWVALID && M_WVALID;
            M_BRESP  = AXI_DECERR;

        end

    end


    // ============================================================
    // Read routing
    // ============================================================

    always_comb begin

        M_ARREADY = 1'b0;

        RAM_rd_en   = 1'b0;
        RAM_rd_addr = M_ARADDR;

        GPIO_rd_en   = 1'b0;
        GPIO_rd_addr = M_ARADDR;


        if (read_ram_sel) begin

            M_ARREADY = 1'b1;
            RAM_rd_en = M_ARVALID;

        end
        else if (read_gpio_sel) begin

            M_ARREADY = 1'b1;
            GPIO_rd_en = M_ARVALID;

        end

    end


    // ============================================================
    // Read response routing
    // ============================================================

    always_comb begin

        M_RVALID = 1'b0;
        M_RDATA  = '0;
        M_RRESP  = AXI_DECERR;

        if (read_ram_sel) begin

            M_RVALID = M_ARVALID;
            M_RDATA  = RAM_rd_data;
            M_RRESP  = RAM_rd_resp;

        end
        else if (read_gpio_sel) begin

            M_RVALID = M_ARVALID;
            M_RDATA  = GPIO_rd_data;
            M_RRESP  = GPIO_rd_resp;

        end
        else if (read_decerr) begin

            M_RVALID = M_ARVALID;
            M_RDATA  = '0;
            M_RRESP  = AXI_DECERR;

        end

    end

endmodule
