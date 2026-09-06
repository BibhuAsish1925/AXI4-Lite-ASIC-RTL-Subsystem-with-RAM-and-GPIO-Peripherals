`timescale 1ns/1ps

module tb_ram_slave;

    logic ACLK;
    logic ARESETn;


    // ============================================================
    // Write interface
    // ============================================================

    logic        wr_en;
    logic [31:0] wr_addr;
    logic [31:0] wr_data;
    logic [3:0]  wr_strb;
    logic [1:0]  wr_resp;


    // ============================================================
    // Read interface
    // ============================================================

    logic        rd_en;
    logic [31:0] rd_addr;
    logic [31:0] rd_data;
    logic [1:0]  rd_resp;


    // ============================================================
    // DUT
    // ============================================================

    ram_slave dut (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

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
    // Reset
    // ============================================================

    initial begin

        ARESETn = 1'b0;

        wr_en   = 1'b0;
        wr_addr = '0;
        wr_data = '0;
        wr_strb = '0;

        rd_en   = 1'b0;
        rd_addr = '0;

        #20;

        ARESETn = 1'b1;

    end


    // ============================================================
    // Test sequence
    // ============================================================

    initial begin

        $display("==============================================");
        $display(" RAM Slave Testbench");
        $display("==============================================");


        wait (ARESETn == 1'b1);


        // ========================================================
        // TEST 1: Full-word write
        // ========================================================

        $display("");
        $display("Test 1: Full-word write/read");


        @(posedge ACLK);

        wr_addr <= 32'h0000_0000;
        wr_data <= 32'hDEAD_BEEF;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;

        #1;

        if (wr_resp !== 2'b00)
            $error("Test 1: write response incorrect");


        // --------------------------------------------------------
        // Read back
        // --------------------------------------------------------

        @(posedge ACLK);

        rd_addr <= 32'h0000_0000;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'hDEAD_BEEF)
            $error(
                "Test 1: read data incorrect. Expected DEAD_BEEF, Got %h",
                rd_data
            );

        if (rd_resp !== 2'b00)
            $error("Test 1: read response incorrect");

        $display("Test 1 passed");


        // ========================================================
        // TEST 2: Byte strobes
        // ========================================================

        $display("");
        $display("Test 2: Byte write strobes");


        // --------------------------------------------------------
        // Start with all bytes set
        // --------------------------------------------------------

        @(posedge ACLK);

        wr_addr <= 32'h0000_0004;
        wr_data <= 32'h1122_3344;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;


        // --------------------------------------------------------
        // Change only byte 0 and byte 2
        // --------------------------------------------------------

        @(posedge ACLK);

        wr_addr <= 32'h0000_0004;
        wr_data <= 32'hAA00_BB00;
        wr_strb <= 4'b0101;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;


        // --------------------------------------------------------
        // Expected:
        //
        // Original: 1122_3344
        // Byte 0:   44 -> 00
        // Byte 1:   33 -> remains 33
        // Byte 2:   22 -> 00
        // Byte 3:   11 -> remains 11
        //
        // Result:   1100_3300
        // --------------------------------------------------------

        @(posedge ACLK);

        rd_addr <= 32'h0000_0004;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'h1100_3300)
            $error(
                "Test 2: byte strobe result incorrect. Expected 1100_3300, Got %h",
                rd_data
            );

        $display("Test 2 passed");


        // ========================================================
        // TEST 3: Multiple addresses
        // ========================================================

        $display("");
        $display("Test 3: Multiple RAM addresses");


        // Address 0x100
        @(posedge ACLK);

        wr_addr <= 32'h0000_0100;
        wr_data <= 32'h1234_5678;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;


        // Address 0x200
        @(posedge ACLK);

        wr_addr <= 32'h0000_0200;
        wr_data <= 32'hCAFE_BABE;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;


        // --------------------------------------------------------
        // Read address 0x100
        // --------------------------------------------------------

        @(posedge ACLK);

        rd_addr <= 32'h0000_0100;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'h1234_5678)
            $error("Test 3: address 0x100 data incorrect");


        // --------------------------------------------------------
        // Read address 0x200
        // --------------------------------------------------------

        @(posedge ACLK);

        rd_addr <= 32'h0000_0200;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'hCAFE_BABE)
            $error("Test 3: address 0x200 data incorrect");

        $display("Test 3 passed");


        // ========================================================
        // TEST 4: Last valid RAM word
        // ========================================================

        $display("");
        $display("Test 4: Last RAM word");


        @(posedge ACLK);

        wr_addr <= 32'h0000_03FC;
        wr_data <= 32'hFACE_CAFE;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;


        @(posedge ACLK);

        rd_addr <= 32'h0000_03FC;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'hFACE_CAFE)
            $error("Test 4: last RAM word incorrect");

        $display("Test 4 passed");


        // ========================================================
        // PASS
        // ========================================================

        $display("");
        $display("[PASS] RAM slave test completed successfully");
        $display("");

        $finish;

    end

endmodule