`timescale 1ns/1ps

module tb_axi4_lite_interconnect;

    // ============================================================
    // Clock and reset
    // ============================================================

    logic ACLK;
    logic ARESETn;


    // ============================================================
    // AXI4-Lite master-side signals
    // ============================================================

    logic [31:0] M_AWADDR;
    logic        M_AWVALID;
    logic        M_AWREADY;

    logic [31:0] M_WDATA;
    logic [3:0]  M_WSTRB;
    logic        M_WVALID;
    logic        M_WREADY;

    logic [1:0]  M_BRESP;
    logic        M_BVALID;
    logic        M_BREADY;

    logic [31:0] M_ARADDR;
    logic        M_ARVALID;
    logic        M_ARREADY;

    logic [31:0] M_RDATA;
    logic [1:0]  M_RRESP;
    logic        M_RVALID;
    logic        M_RREADY;


    // ============================================================
    // RAM interface
    // ============================================================

    logic        RAM_wr_en;
    logic [31:0] RAM_wr_addr;
    logic [31:0] RAM_wr_data;
    logic [3:0]  RAM_wr_strb;
    logic [1:0]  RAM_wr_resp;

    logic        RAM_rd_en;
    logic [31:0] RAM_rd_addr;
    logic [31:0] RAM_rd_data;
    logic [1:0]  RAM_rd_resp;


    // ============================================================
    // GPIO interface
    // ============================================================

    logic        GPIO_wr_en;
    logic [31:0] GPIO_wr_addr;
    logic [31:0] GPIO_wr_data;
    logic [3:0]  GPIO_wr_strb;
    logic [1:0]  GPIO_wr_resp;

    logic        GPIO_rd_en;
    logic [31:0] GPIO_rd_addr;
    logic [31:0] GPIO_rd_data;
    logic [1:0]  GPIO_rd_resp;


    // ============================================================
    // DUT
    // ============================================================

    axi4_lite_interconnect dut (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .M_AWADDR(M_AWADDR),
        .M_AWVALID(M_AWVALID),
        .M_AWREADY(M_AWREADY),

        .M_WDATA(M_WDATA),
        .M_WSTRB(M_WSTRB),
        .M_WVALID(M_WVALID),
        .M_WREADY(M_WREADY),

        .M_BRESP(M_BRESP),
        .M_BVALID(M_BVALID),
        .M_BREADY(M_BREADY),

        .M_ARADDR(M_ARADDR),
        .M_ARVALID(M_ARVALID),
        .M_ARREADY(M_ARREADY),

        .M_RDATA(M_RDATA),
        .M_RRESP(M_RRESP),
        .M_RVALID(M_RVALID),
        .M_RREADY(M_RREADY),

        .RAM_wr_en(RAM_wr_en),
        .RAM_wr_addr(RAM_wr_addr),
        .RAM_wr_data(RAM_wr_data),
        .RAM_wr_strb(RAM_wr_strb),
        .RAM_wr_resp(RAM_wr_resp),

        .RAM_rd_en(RAM_rd_en),
        .RAM_rd_addr(RAM_rd_addr),
        .RAM_rd_data(RAM_rd_data),
        .RAM_rd_resp(RAM_rd_resp),

        .GPIO_wr_en(GPIO_wr_en),
        .GPIO_wr_addr(GPIO_wr_addr),
        .GPIO_wr_data(GPIO_wr_data),
        .GPIO_wr_strb(GPIO_wr_strb),
        .GPIO_wr_resp(GPIO_wr_resp),

        .GPIO_rd_en(GPIO_rd_en),
        .GPIO_rd_addr(GPIO_rd_addr),
        .GPIO_rd_data(GPIO_rd_data),
        .GPIO_rd_resp(GPIO_rd_resp)
    );


    // ============================================================
    // Clock generation
    // ============================================================

    initial begin
        ACLK = 1'b0;

        forever #5 ACLK = ~ACLK;
    end


    // ============================================================
    // Reset
    // ============================================================

    initial begin

        ARESETn = 1'b0;

        #20;

        ARESETn = 1'b1;

    end


    // ============================================================
    // Main test sequence
    // ============================================================

    initial begin

        $display("==============================================");
        $display(" AXI4-Lite Interconnect Testbench");
        $display("==============================================");


        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        M_AWADDR  = 32'h0000_0000;
        M_AWVALID = 1'b0;

        M_WDATA   = 32'h0000_0000;
        M_WSTRB   = 4'b0000;
        M_WVALID  = 1'b0;

        M_BREADY  = 1'b1;

        M_ARADDR  = 32'h0000_0000;
        M_ARVALID = 1'b0;

        M_RREADY  = 1'b1;

        RAM_wr_resp = 2'b00;
        RAM_rd_data = 32'h0000_0000;
        RAM_rd_resp = 2'b00;

        GPIO_wr_resp = 2'b00;
        GPIO_rd_data = 32'h0000_0000;
        GPIO_rd_resp = 2'b00;


        wait (ARESETn == 1'b1);


        // ========================================================
        // Test 1: RAM write routing
        // ========================================================

        $display("");
        $display("Test 1: RAM write routing");

        M_AWADDR  = 32'h0000_0100;
        M_AWVALID = 1'b1;

        M_WDATA   = 32'hDEAD_BEEF;
        M_WSTRB   = 4'b1111;
        M_WVALID  = 1'b1;

        #1;

        if (M_AWREADY !== 1'b1)
            $error("Test 1: M_AWREADY should be high for RAM");

        if (M_WREADY !== 1'b1)
            $error("Test 1: M_WREADY should be high for RAM");

        if (RAM_wr_en !== 1'b1)
            $error("Test 1: RAM_wr_en should be high");

        if (RAM_wr_addr !== 32'h0000_0100)
            $error("Test 1: RAM address incorrect");

        if (RAM_wr_data !== 32'hDEAD_BEEF)
            $error("Test 1: RAM write data incorrect");

        if (RAM_wr_strb !== 4'b1111)
            $error("Test 1: RAM write strobe incorrect");

        if (GPIO_wr_en !== 1'b0)
            $error("Test 1: GPIO must not receive RAM write");

        M_AWVALID = 1'b0;
        M_WVALID  = 1'b0;

        #1;

        $display("Test 1 passed");


        // ========================================================
        // Test 2: GPIO write routing
        // ========================================================

        $display("");
        $display("Test 2: GPIO write routing");

        M_AWADDR  = 32'h0000_1000;
        M_AWVALID = 1'b1;

        M_WDATA   = 32'h1234_5678;
        M_WSTRB   = 4'b1111;
        M_WVALID  = 1'b1;

        #1;

        if (M_AWREADY !== 1'b1)
            $error("Test 2: M_AWREADY should be high for GPIO");

        if (M_WREADY !== 1'b1)
            $error("Test 2: M_WREADY should be high for GPIO");

        if (GPIO_wr_en !== 1'b1)
            $error("Test 2: GPIO_wr_en should be high");

        if (GPIO_wr_addr !== 32'h0000_1000)
            $error("Test 2: GPIO address incorrect");

        if (GPIO_wr_data !== 32'h1234_5678)
            $error("Test 2: GPIO write data incorrect");

        if (GPIO_wr_strb !== 4'b1111)
            $error("Test 2: GPIO write strobe incorrect");

        if (RAM_wr_en !== 1'b0)
            $error("Test 2: RAM must not receive GPIO write");

        M_AWVALID = 1'b0;
        M_WVALID  = 1'b0;

        #1;

        $display("Test 2 passed");


        // ========================================================
        // Test 3: Unmapped write
        // ========================================================

        $display("");
        $display("Test 3: Unmapped write");

        M_AWADDR  = 32'h0000_2000;
        M_AWVALID = 1'b1;

        M_WDATA   = 32'hCAFE_BABE;
        M_WSTRB   = 4'b1111;
        M_WVALID  = 1'b1;

        #1;

        if (M_BVALID !== 1'b1)
            $error("Test 3: BVALID should be high");

        if (M_BRESP !== 2'b11)
            $error(
                "Test 3: expected DECERR, got %b",
                M_BRESP
            );

        if (RAM_wr_en !== 1'b0)
            $error("Test 3: RAM must not receive unmapped write");

        if (GPIO_wr_en !== 1'b0)
            $error("Test 3: GPIO must not receive unmapped write");

        M_AWVALID = 1'b0;
        M_WVALID  = 1'b0;

        #1;

        $display("Test 3 passed");


        // ========================================================
        // Test 4: RAM read routing
        // ========================================================

        $display("");
        $display("Test 4: RAM read routing");

        RAM_rd_data = 32'hFACE_CAFE;
        RAM_rd_resp = 2'b00;

        M_ARADDR  = 32'h0000_0200;
        M_ARVALID = 1'b1;

        #1;

        if (M_ARREADY !== 1'b1)
            $error("Test 4: ARREADY should be high for RAM");

        if (RAM_rd_en !== 1'b1)
            $error("Test 4: RAM_rd_en should be high");

        if (RAM_rd_addr !== 32'h0000_0200)
            $error("Test 4: RAM read address incorrect");

        if (GPIO_rd_en !== 1'b0)
            $error("Test 4: GPIO must not receive RAM read");

        if (M_RVALID !== 1'b1)
            $error("Test 4: RVALID should be high");

        if (M_RDATA !== 32'hFACE_CAFE)
            $error("Test 4: read data incorrect");

        if (M_RRESP !== 2'b00)
            $error("Test 4: read response incorrect");

        M_ARVALID = 1'b0;

        #1;

        $display("Test 4 passed");


        // ========================================================
        // Test 5: GPIO read routing
        // ========================================================

        $display("");
        $display("Test 5: GPIO read routing");

        GPIO_rd_data = 32'hA5A5_5A5A;
        GPIO_rd_resp = 2'b00;

        M_ARADDR  = 32'h0000_1004;
        M_ARVALID = 1'b1;

        #1;

        if (M_ARREADY !== 1'b1)
            $error("Test 5: ARREADY should be high for GPIO");

        if (GPIO_rd_en !== 1'b1)
            $error("Test 5: GPIO_rd_en should be high");

        if (GPIO_rd_addr !== 32'h0000_1004)
            $error("Test 5: GPIO read address incorrect");

        if (RAM_rd_en !== 1'b0)
            $error("Test 5: RAM must not receive GPIO read");

        if (M_RVALID !== 1'b1)
            $error("Test 5: RVALID should be high");

        if (M_RDATA !== 32'hA5A5_5A5A)
            $error("Test 5: read data incorrect");

        if (M_RRESP !== 2'b00)
            $error("Test 5: read response incorrect");

        M_ARVALID = 1'b0;

        #1;

        $display("Test 5 passed");


        // ========================================================
        // Test 6: Unmapped read
        // ========================================================

        $display("");
        $display("Test 6: Unmapped read");

        M_ARADDR  = 32'h0000_3000;
        M_ARVALID = 1'b1;

        #1;

        if (M_RVALID !== 1'b1)
            $error("Test 6: RVALID should be high");

        if (M_RDATA !== 32'h0000_0000)
            $error("Test 6: unmapped read data should be zero");

        if (M_RRESP !== 2'b11)
            $error(
                "Test 6: expected DECERR, got %b",
                M_RRESP
            );

        if (RAM_rd_en !== 1'b0)
            $error("Test 6: RAM must not receive unmapped read");

        if (GPIO_rd_en !== 1'b0)
            $error("Test 6: GPIO must not receive unmapped read");

        M_ARVALID = 1'b0;

        #1;

        $display("Test 6 passed");


        // ========================================================
        // Test 7: RAM boundary
        // ========================================================

        $display("");
        $display("Test 7: RAM boundary");

        M_AWADDR  = 32'h0000_03FF;
        M_AWVALID = 1'b1;

        M_WDATA   = 32'h1111_2222;
        M_WSTRB   = 4'b1111;
        M_WVALID  = 1'b1;

        #1;

        if (RAM_wr_en !== 1'b1)
            $error("Test 7: last RAM address should select RAM");

        if (GPIO_wr_en !== 1'b0)
            $error("Test 7: last RAM address selected GPIO");

        M_AWVALID = 1'b0;
        M_WVALID  = 1'b0;

        #1;

        $display("Test 7 passed");


        // ========================================================
        // Test 8: GPIO boundary
        // ========================================================

        $display("");
        $display("Test 8: GPIO boundary");

        M_AWADDR  = 32'h0000_10FF;
        M_AWVALID = 1'b1;

        M_WDATA   = 32'h3333_4444;
        M_WSTRB   = 4'b1111;
        M_WVALID  = 1'b1;

        #1;

        if (GPIO_wr_en !== 1'b1)
            $error("Test 8: last GPIO address should select GPIO");

        if (RAM_wr_en !== 1'b0)
            $error("Test 8: last GPIO address selected RAM");

        M_AWVALID = 1'b0;
        M_WVALID  = 1'b0;

        #1;

        $display("Test 8 passed");


        // ========================================================
        // Test 9: Write strobe propagation
        // ========================================================

        $display("");
        $display("Test 9: Write strobe propagation");

        M_AWADDR  = 32'h0000_0010;
        M_AWVALID = 1'b1;

        M_WDATA   = 32'h00BB_00AA;
        M_WSTRB   = 4'b0101;
        M_WVALID  = 1'b1;

        #1;

        if (RAM_wr_strb !== 4'b0101)
            $error("Test 9: RAM WSTRB propagation failed");

        M_AWVALID = 1'b0;
        M_WVALID  = 1'b0;

        #1;

        $display("Test 9 passed");


        // ========================================================
        // Final result
        // ========================================================

        $display("");
        $display("[PASS] AXI4-Lite interconnect test completed successfully");
        $display("");

        $finish;

    end

endmodule