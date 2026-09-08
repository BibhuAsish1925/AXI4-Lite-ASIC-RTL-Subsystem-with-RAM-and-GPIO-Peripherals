`timescale 1ns/1ps

module tb_axi4_lite_slave;

    // ============================================================
    // Clock and reset
    // ============================================================

    logic ACLK;
    logic ARESETn;


    // ============================================================
    // AXI Write Address
    // ============================================================

    logic [31:0] S_AWADDR;
    logic        S_AWVALID;
    logic        S_AWREADY;


    // ============================================================
    // AXI Write Data
    // ============================================================

    logic [31:0] S_WDATA;
    logic [3:0]  S_WSTRB;
    logic        S_WVALID;
    logic        S_WREADY;


    // ============================================================
    // AXI Write Response
    // ============================================================

    logic [1:0] S_BRESP;
    logic       S_BVALID;
    logic       S_BREADY;


    // ============================================================
    // AXI Read Address
    // ============================================================

    logic [31:0] S_ARADDR;
    logic        S_ARVALID;
    logic        S_ARREADY;


    // ============================================================
    // AXI Read Data
    // ============================================================

    logic [31:0] S_RDATA;
    logic [1:0]  S_RRESP;
    logic        S_RVALID;
    logic        S_RREADY;


    // ============================================================
    // Backend write interface
    // ============================================================

    logic        wr_en;
    logic [31:0] wr_addr;
    logic [31:0] wr_data;
    logic [3:0]  wr_strb;

    logic [1:0]  wr_resp;


    // ============================================================
    // Backend read interface
    // ============================================================

    logic        rd_en;
    logic [31:0] rd_addr;

    logic [31:0] rd_data;
    logic [1:0]  rd_resp;


    // ============================================================
    // DUT
    // ============================================================

    axi4_lite_slave dut (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .S_AWADDR(S_AWADDR),
        .S_AWVALID(S_AWVALID),
        .S_AWREADY(S_AWREADY),

        .S_WDATA(S_WDATA),
        .S_WSTRB(S_WSTRB),
        .S_WVALID(S_WVALID),
        .S_WREADY(S_WREADY),

        .S_BRESP(S_BRESP),
        .S_BVALID(S_BVALID),
        .S_BREADY(S_BREADY),

        .S_ARADDR(S_ARADDR),
        .S_ARVALID(S_ARVALID),
        .S_ARREADY(S_ARREADY),

        .S_RDATA(S_RDATA),
        .S_RRESP(S_RRESP),
        .S_RVALID(S_RVALID),
        .S_RREADY(S_RREADY),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_strb(wr_strb),
        .wr_resp(wr_resp),

        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_resp(rd_resp)

    );


    // ============================================================
    // Clock
    // ============================================================

    initial begin

        ACLK = 1'b0;

        forever #5 ACLK = ~ACLK;

    end


    // ============================================================
    // Reset and initial values
    // ============================================================

    initial begin

        ARESETn = 1'b0;

        S_AWADDR  = '0;
        S_AWVALID = 1'b0;

        S_WDATA   = '0;
        S_WSTRB   = '0;
        S_WVALID  = 1'b0;

        S_BREADY  = 1'b0;

        S_ARADDR  = '0;
        S_ARVALID = 1'b0;

        S_RREADY  = 1'b0;

        wr_resp = 2'b00;

        rd_data = 32'h1234_5678;
        rd_resp = 2'b00;

        #20;

        ARESETn = 1'b1;

    end


    // ============================================================
    // Test sequence
    // ============================================================

    initial begin

        $display("==============================================");
        $display(" AXI4-Lite Slave Testbench");
        $display("==============================================");


        wait (ARESETn == 1'b1);


        // ========================================================
        // TEST 1
        // AW arrives before W
        // ========================================================

        $display("");
        $display("Test 1: AW before W");


        @(posedge ACLK);

        S_AWADDR  <= 32'h0000_1000;
        S_AWVALID <= 1'b1;


        wait (S_AWREADY == 1'b1);

        @(posedge ACLK);

        S_AWVALID <= 1'b0;


        @(posedge ACLK);

        S_WDATA  <= 32'hDEAD_BEEF;
        S_WSTRB  <= 4'b1111;
        S_WVALID <= 1'b1;


        wait (S_WREADY == 1'b1);

        @(posedge ACLK);

        S_WVALID <= 1'b0;


        // --------------------------------------------------------
        // Check backend write
        // --------------------------------------------------------

        wait (wr_en == 1'b1);

        if (wr_addr !== 32'h0000_1000)
            $error("Test 1: incorrect write address");

        if (wr_data !== 32'hDEAD_BEEF)
            $error("Test 1: incorrect write data");

        if (wr_strb !== 4'b1111)
            $error("Test 1: incorrect write strobes");


        // --------------------------------------------------------
        // Accept write response
        // --------------------------------------------------------

        S_BREADY <= 1'b1;

        wait (S_BVALID == 1'b1);

        if (S_BRESP !== 2'b00)
            $error("Test 1: incorrect BRESP");

        @(posedge ACLK);

        S_BREADY <= 1'b0;

        $display("Test 1 passed");


        // ========================================================
        // TEST 2
        // W arrives before AW
        // ========================================================

        $display("");
        $display("Test 2: W before AW");


        @(posedge ACLK);

        S_WDATA  <= 32'hA5A5_5A5A;
        S_WSTRB  <= 4'b0011;
        S_WVALID <= 1'b1;


        wait (S_WREADY == 1'b1);

        @(posedge ACLK);

        S_WVALID <= 1'b0;


        @(posedge ACLK);

        S_AWADDR  <= 32'h0000_0020;
        S_AWVALID <= 1'b1;


        wait (S_AWREADY == 1'b1);

        @(posedge ACLK);

        S_AWVALID <= 1'b0;


        // --------------------------------------------------------
        // Check backend write
        // --------------------------------------------------------

        wait (wr_en == 1'b1);

        if (wr_addr !== 32'h0000_0020)
            $error("Test 2: incorrect write address");

        if (wr_data !== 32'hA5A5_5A5A)
            $error("Test 2: incorrect write data");

        if (wr_strb !== 4'b0011)
            $error("Test 2: incorrect write strobes");


        // --------------------------------------------------------
        // Accept response
        // --------------------------------------------------------

        S_BREADY <= 1'b1;

        wait (S_BVALID == 1'b1);

        if (S_BRESP !== 2'b00)
            $error("Test 2: incorrect BRESP");

        @(posedge ACLK);

        S_BREADY <= 1'b0;

        $display("Test 2 passed");


        // ========================================================
        // TEST 3
        // Read transaction
        // ========================================================

        $display("");
        $display("Test 3: Read transaction");


        rd_data <= 32'hCAFE_BABE;
        rd_resp <= 2'b00;


        @(posedge ACLK);

        S_ARADDR  <= 32'h0000_0040;
        S_ARVALID <= 1'b1;


        wait (S_ARREADY == 1'b1);

        @(posedge ACLK);

        S_ARVALID <= 1'b0;


        // --------------------------------------------------------
        // Check backend read request
        // --------------------------------------------------------

        wait (rd_en == 1'b1);

        if (rd_addr !== 32'h0000_0040)
            $error("Test 3: incorrect read address");


        // --------------------------------------------------------
        // Accept read response
        // --------------------------------------------------------

        S_RREADY <= 1'b1;

        wait (S_RVALID == 1'b1);

        if (S_RDATA !== 32'hCAFE_BABE)
            $error("Test 3: incorrect read data");

        if (S_RRESP !== 2'b00)
            $error("Test 3: incorrect RRESP");

        @(posedge ACLK);

        S_RREADY <= 1'b0;

        $display("Test 3 passed");


        // ========================================================
        // PASS
        // ========================================================

        $display("");
        $display("[PASS] AXI4-Lite slave test completed successfully");
        $display("");

        $finish;

    end

endmodule