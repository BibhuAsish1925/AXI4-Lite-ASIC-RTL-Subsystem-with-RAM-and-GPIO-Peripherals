module axi4_lite_top #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input  logic ACLK,
    input  logic ARESETn,

    // ============================================================
    // USER WRITE INTERFACE
    // ============================================================

    input  logic [ADDR_WIDTH-1:0]   write_addr,
    input  logic [DATA_WIDTH-1:0]   write_data,
    input  logic [DATA_WIDTH/8-1:0] write_strb,
    input  logic                    write_valid,

    output logic                    write_ready,
    output logic [1:0]              write_resp,
    output logic                    write_resp_valid,

    // ============================================================
    // USER READ INTERFACE
    // ============================================================

    input  logic [ADDR_WIDTH-1:0]   read_addr,
    input  logic                    read_valid,

    output logic                    read_ready,
    output logic [DATA_WIDTH-1:0]   read_data,
    output logic [1:0]              read_resp,
    output logic                    read_resp_valid,

    // ============================================================
    // GPIO
    // ============================================================

    input  logic [DATA_WIDTH-1:0]   gpio_input,
    output logic [DATA_WIDTH-1:0]   gpio_output,
    output logic [DATA_WIDTH-1:0]   gpio_direction
);

    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    localparam logic [ADDR_WIDTH-1:0] GPIO_BASE =
        32'h0000_1000;

    localparam logic [1:0] AXI_OKAY =
        2'b00;

    localparam logic [1:0] AXI_DECERR =
        2'b11;


    // ============================================================
    // AXI MASTER
    // ============================================================

    logic [ADDR_WIDTH-1:0]   M_AWADDR;
    logic                    M_AWVALID;
    logic                    M_AWREADY;

    logic [DATA_WIDTH-1:0]   M_WDATA;
    logic [STRB_WIDTH-1:0]   M_WSTRB;
    logic                    M_WVALID;
    logic                    M_WREADY;

    logic [1:0]              M_BRESP;
    logic                    M_BVALID;
    logic                    M_BREADY;

    logic [ADDR_WIDTH-1:0]   M_ARADDR;
    logic                    M_ARVALID;
    logic                    M_ARREADY;

    logic [DATA_WIDTH-1:0]   M_RDATA;
    logic [1:0]              M_RRESP;
    logic                    M_RVALID;
    logic                    M_RREADY;


    // ============================================================
    // MASTER INSTANCE
    // ============================================================

    axi4_lite_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_master (
        .ACLK             (ACLK),
        .ARESETn          (ARESETn),

        .write_addr       (write_addr),
        .write_data       (write_data),
        .write_strb       (write_strb),
        .write_valid      (write_valid),
        .write_ready      (write_ready),
        .write_resp       (write_resp),
        .write_resp_valid (write_resp_valid),

        .read_addr        (read_addr),
        .read_valid       (read_valid),
        .read_ready       (read_ready),
        .read_data        (read_data),
        .read_resp        (read_resp),
        .read_resp_valid  (read_resp_valid),

        .M_AWADDR         (M_AWADDR),
        .M_AWVALID        (M_AWVALID),
        .M_AWREADY        (M_AWREADY),

        .M_WDATA          (M_WDATA),
        .M_WSTRB          (M_WSTRB),
        .M_WVALID         (M_WVALID),
        .M_WREADY         (M_WREADY),

        .M_BRESP          (M_BRESP),
        .M_BVALID         (M_BVALID),
        .M_BREADY         (M_BREADY),

        .M_ARADDR         (M_ARADDR),
        .M_ARVALID        (M_ARVALID),
        .M_ARREADY        (M_ARREADY),

        .M_RDATA          (M_RDATA),
        .M_RRESP          (M_RRESP),
        .M_RVALID         (M_RVALID),
        .M_RREADY         (M_RREADY)
    );


    // ============================================================
    // ADDRESS DECODERS
    // ============================================================

    logic write_ram_sel;
    logic write_gpio_sel;
    logic write_decoder_decerr;

    logic read_ram_sel;
    logic read_gpio_sel;
    logic read_decoder_decerr;


    axi4_lite_addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_write_decoder (
        .addr     (M_AWADDR),
        .ram_sel  (write_ram_sel),
        .gpio_sel (write_gpio_sel),
        .decerr   (write_decoder_decerr)
    );


    axi4_lite_addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_read_decoder (
        .addr     (M_ARADDR),
        .ram_sel  (read_ram_sel),
        .gpio_sel (read_gpio_sel),
        .decerr   (read_decoder_decerr)
    );


    // ============================================================
    // RAM INTERFACE
    // ============================================================

    logic                    RAM_wr_en;
    logic [ADDR_WIDTH-1:0]   RAM_wr_addr;
    logic [DATA_WIDTH-1:0]   RAM_wr_data;
    logic [STRB_WIDTH-1:0]   RAM_wr_strb;
    logic [1:0]              RAM_wr_resp;

    logic                    RAM_rd_en;
    logic [ADDR_WIDTH-1:0]   RAM_rd_addr;
    logic [DATA_WIDTH-1:0]   RAM_rd_data;
    logic [1:0]              RAM_rd_resp;


    // ============================================================
    // GPIO INTERFACE
    // ============================================================

    logic                    GPIO_wr_en;
    logic [ADDR_WIDTH-1:0]   GPIO_wr_addr;
    logic [DATA_WIDTH-1:0]   GPIO_wr_data;
    logic [STRB_WIDTH-1:0]   GPIO_wr_strb;
    logic [1:0]              GPIO_wr_resp;

    logic                    GPIO_rd_en;
    logic [ADDR_WIDTH-1:0]   GPIO_rd_addr;
    logic [DATA_WIDTH-1:0]   GPIO_rd_data;
    logic [1:0]              GPIO_rd_resp;


    // ============================================================
    // WRITE TRANSACTION CONTROLLER
    // ============================================================

    typedef enum logic [1:0] {
        WR_IDLE,
        WR_WAIT_RESP,
        WR_RESP
    } write_state_t;

    write_state_t write_state;

    logic write_target_ram;
    logic write_target_gpio;


    // ------------------------------------------------------------
    // MASTER READY
    // ------------------------------------------------------------

    always_comb begin

        M_AWREADY = 1'b0;
        M_WREADY  = 1'b0;

        if (write_state == WR_IDLE) begin
            M_AWREADY = 1'b1;
            M_WREADY  = 1'b1;
        end

    end


    // ------------------------------------------------------------
    // WRITE REQUEST TO PERIPHERALS
    // ------------------------------------------------------------

    always_comb begin

        RAM_wr_en = 1'b0;

        GPIO_wr_en = 1'b0;

        RAM_wr_addr = M_AWADDR;
        RAM_wr_data = M_WDATA;
        RAM_wr_strb = M_WSTRB;

        GPIO_wr_addr = M_AWADDR - GPIO_BASE;
        GPIO_wr_data = M_WDATA;
        GPIO_wr_strb = M_WSTRB;


        if (
            (write_state == WR_IDLE) &&
            M_AWVALID &&
            M_AWREADY &&
            M_WVALID &&
            M_WREADY
        ) begin

            if (write_ram_sel) begin
                RAM_wr_en = 1'b1;
            end
            else if (write_gpio_sel) begin
                GPIO_wr_en = 1'b1;
            end

        end

    end


    // ------------------------------------------------------------
    // WRITE STATE MACHINE
    // ------------------------------------------------------------

    always_ff @(posedge ACLK) begin

        if (!ARESETn) begin

            write_state <= WR_IDLE;

            write_target_ram   <= 1'b0;
            write_target_gpio  <= 1'b0;

            M_BVALID <= 1'b0;
            M_BRESP  <= AXI_OKAY;

        end
        else begin

            case (write_state)

                // =================================================
                // IDLE
                // =================================================

                WR_IDLE: begin

                    M_BVALID <= 1'b0;

                    if (
                        M_AWVALID &&
                        M_AWREADY &&
                        M_WVALID &&
                        M_WREADY
                    ) begin

                        write_target_ram <=
                            write_ram_sel;

                        write_target_gpio <=
                            write_gpio_sel;


                        write_state <= WR_WAIT_RESP;

                    end

                end


                // =================================================
                // WAIT ONE CLOCK FOR RAM/GPIO RESPONSE
                // =================================================

                WR_WAIT_RESP: begin

                    if (write_target_ram) begin

                        M_BRESP <= RAM_wr_resp;

                    end
                    else if (write_target_gpio) begin

                        M_BRESP <= GPIO_wr_resp;

                    end
else if (write_decoder_decerr) begin

    M_BRESP <= AXI_DECERR;

end

                    M_BVALID <= 1'b1;

                    write_state <= WR_RESP;

                end


                // =================================================
                // HOLD RESPONSE UNTIL MASTER ACCEPTS IT
                // =================================================

                WR_RESP: begin

                    if (M_BVALID && M_BREADY) begin

                        M_BVALID <= 1'b0;

                        write_target_ram    <= 1'b0;
                        write_target_gpio   <= 1'b0;

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
    // READ TRANSACTION CONTROLLER
    // ============================================================

    typedef enum logic [1:0] {
        RD_IDLE,
        RD_WAIT_DATA,
        RD_RESP
    } read_state_t;

    read_state_t read_state;

    logic read_target_ram;
    logic read_target_gpio;


    // ------------------------------------------------------------
    // MASTER READ READY
    // ------------------------------------------------------------

    always_comb begin

        M_ARREADY = 1'b0;

        if (read_state == RD_IDLE) begin
            M_ARREADY = 1'b1;
        end

    end


    // ------------------------------------------------------------
    // READ REQUEST TO PERIPHERALS
    // ------------------------------------------------------------

    always_comb begin

        RAM_rd_en = 1'b0;
        GPIO_rd_en = 1'b0;

        RAM_rd_addr = M_ARADDR;

        GPIO_rd_addr = M_ARADDR - GPIO_BASE;


        if (
            (read_state == RD_IDLE) &&
            M_ARVALID &&
            M_ARREADY
        ) begin

            if (read_ram_sel) begin

                RAM_rd_en = 1'b1;

            end
            else if (read_gpio_sel) begin

                GPIO_rd_en = 1'b1;

            end

        end

    end


    // ------------------------------------------------------------
    // READ STATE MACHINE
    // ------------------------------------------------------------

    always_ff @(posedge ACLK) begin

        if (!ARESETn) begin

            read_state <= RD_IDLE;

            read_target_ram    <= 1'b0;
            read_target_gpio   <= 1'b0;

            M_RVALID <= 1'b0;
            M_RDATA  <= '0;
            M_RRESP  <= AXI_OKAY;

        end
        else begin

            case (read_state)

                // =================================================
                // IDLE
                // =================================================

                RD_IDLE: begin

                    M_RVALID <= 1'b0;

                    if (
                        M_ARVALID &&
                        M_ARREADY
                    ) begin

                        read_target_ram <=
                            read_ram_sel;

                        read_target_gpio <=
                            read_gpio_sel;


                        read_state <= RD_WAIT_DATA;

                    end

                end


                // =================================================
                // WAIT FOR REGISTERED PERIPHERAL READ DATA
                // =================================================

                RD_WAIT_DATA: begin

                    if (read_target_ram) begin

                        M_RDATA <= RAM_rd_data;
                        M_RRESP <= RAM_rd_resp;

                    end
                    else if (read_target_gpio) begin

                        M_RDATA <= GPIO_rd_data;
                        M_RRESP <= GPIO_rd_resp;

                    end
else if (read_decoder_decerr) begin

    M_RDATA <= '0;
    M_RRESP <= AXI_DECERR;

end

                    M_RVALID <= 1'b1;

                    read_state <= RD_RESP;

                end


                // =================================================
                // HOLD READ RESPONSE
                // =================================================

                RD_RESP: begin

                    if (M_RVALID && M_RREADY) begin

                        M_RVALID <= 1'b0;

                        read_target_ram    <= 1'b0;
                        read_target_gpio   <= 1'b0;

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
    // RAM INSTANCE
    // ============================================================

    ram_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(256)
    ) u_ram (
        .ACLK     (ACLK),
        .ARESETn  (ARESETn),

        .wr_en    (RAM_wr_en),
        .wr_addr  (RAM_wr_addr),
        .wr_data  (RAM_wr_data),
        .wr_strb  (RAM_wr_strb),
        .wr_resp  (RAM_wr_resp),

        .rd_en    (RAM_rd_en),
        .rd_addr  (RAM_rd_addr),
        .rd_data  (RAM_rd_data),
        .rd_resp  (RAM_rd_resp)
    );


    // ============================================================
    // GPIO INSTANCE
    // ============================================================

    gpio_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_gpio (
        .ACLK           (ACLK),
        .ARESETn        (ARESETn),

        .wr_en          (GPIO_wr_en),
        .wr_addr        (GPIO_wr_addr),
        .wr_data        (GPIO_wr_data),
        .wr_strb        (GPIO_wr_strb),
        .wr_resp        (GPIO_wr_resp),

        .rd_en          (GPIO_rd_en),
        .rd_addr        (GPIO_rd_addr),
        .rd_data        (GPIO_rd_data),
        .rd_resp        (GPIO_rd_resp),

        .gpio_input     (gpio_input),
        .gpio_output    (gpio_output),
        .gpio_direction (gpio_direction)
    );

endmodule
