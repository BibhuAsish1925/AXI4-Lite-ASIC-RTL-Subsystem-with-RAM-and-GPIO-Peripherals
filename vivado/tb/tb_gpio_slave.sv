`timescale 1ns/1ps

module tb_gpio_slave;

    // ============================================================
    // Clock and reset
    // ============================================================

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
    // GPIO signals
    // ============================================================

    logic [31:0] gpio_input;
    logic [31:0] gpio_output;
    logic [31:0] gpio_direction;


    // ============================================================
    // DUT
    // ============================================================

    gpio_slave dut (
        .ACLK          (ACLK),
        .ARESETn       (ARESETn),

        .wr_en         (wr_en),
        .wr_addr       (wr_addr),
        .wr_data       (wr_data),
        .wr_strb       (wr_strb),
        .wr_resp       (wr_resp),

        .rd_en         (rd_en),
        .rd_addr       (rd_addr),
        .rd_data       (rd_data),
        .rd_resp       (rd_resp),

        .gpio_input    (gpio_input),
        .gpio_output   (gpio_output),
        .gpio_direction(gpio_direction)
    );


    // ============================================================
    // Clock generation
    // ============================================================

    initial begin
        ACLK = 1'b0;

        forever #5 ACLK = ~ACLK;
    end


    // ============================================================
    // Reset and initial conditions
    // ============================================================

    initial begin

        ARESETn = 1'b0;

        wr_en   = 1'b0;
        wr_addr = 32'h0000_0000;
        wr_data = 32'h0000_0000;
        wr_strb = 4'b0000;

        rd_en   = 1'b0;
        rd_addr = 32'h0000_0000;

        gpio_input = 32'h0000_0000;

        #20;

        ARESETn = 1'b1;

    end


    // ============================================================
    // Main test sequence
    // ============================================================

    initial begin

        $display("==============================================");
        $display(" GPIO Slave Testbench");
        $display("==============================================");


        // Wait for reset to be released

        wait (ARESETn == 1'b1);


        // ========================================================
        // Test 1: Reset values
        // ========================================================

        $display("");
        $display("Test 1: Reset values");

        if (gpio_output !== 32'h0000_0000) begin
            $error("GPIO_OUTPUT reset value incorrect");
        end

        if (gpio_direction !== 32'h0000_0000) begin
            $error("GPIO_DIRECTION reset value incorrect");
        end

        $display("Test 1 passed");


        // ========================================================
        // Test 2: GPIO_OUTPUT write and read
        // ========================================================

        $display("");
        $display("Test 2: GPIO_OUTPUT write/read");


        // Write GPIO_OUTPUT

        @(posedge ACLK);

        wr_addr <= 32'h0000_0000;
        wr_data <= 32'hDEAD_BEEF;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;

        #1;

        if (wr_resp !== 2'b00) begin
            $error("Test 2: GPIO_OUTPUT write response incorrect");
        end

        if (gpio_output !== 32'hDEAD_BEEF) begin
            $error(
                "Test 2: GPIO_OUTPUT incorrect. Expected DEAD_BEEF, Got %h",
                gpio_output
            );
        end


        // Read GPIO_OUTPUT

        @(posedge ACLK);

        rd_addr <= 32'h0000_0000;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'hDEAD_BEEF) begin
            $error(
                "Test 2: GPIO_OUTPUT read incorrect. Expected DEAD_BEEF, Got %h",
                rd_data
            );
        end

        if (rd_resp !== 2'b00) begin
            $error("Test 2: GPIO_OUTPUT read response incorrect");
        end

        $display("Test 2 passed");


        // ========================================================
        // Test 3: GPIO_DIRECTION write and read
        // ========================================================

        $display("");
        $display("Test 3: GPIO_DIRECTION write/read");


        // Write GPIO_DIRECTION

        @(posedge ACLK);

        wr_addr <= 32'h0000_0008;
        wr_data <= 32'hFFFF_00FF;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;

        #1;

        if (wr_resp !== 2'b00) begin
            $error("Test 3: GPIO_DIRECTION write response incorrect");
        end

        if (gpio_direction !== 32'hFFFF_00FF) begin
            $error(
                "Test 3: GPIO_DIRECTION incorrect. Expected FFFF_00FF, Got %h",
                gpio_direction
            );
        end


        // Read GPIO_DIRECTION

        @(posedge ACLK);

        rd_addr <= 32'h0000_0008;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'hFFFF_00FF) begin
            $error(
                "Test 3: GPIO_DIRECTION read incorrect. Expected FFFF_00FF, Got %h",
                rd_data
            );
        end

        if (rd_resp !== 2'b00) begin
            $error("Test 3: GPIO_DIRECTION read response incorrect");
        end

        $display("Test 3 passed");


        // ========================================================
        // Test 4: GPIO_INPUT read
        // ========================================================

        $display("");
        $display("Test 4: GPIO_INPUT read");


        // Drive external GPIO input

        gpio_input = 32'h1234_5678;


        // Read GPIO_INPUT

        @(posedge ACLK);

        rd_addr <= 32'h0000_0004;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'h1234_5678) begin
            $error(
                "Test 4: GPIO_INPUT incorrect. Expected 1234_5678, Got %h",
                rd_data
            );
        end

        if (rd_resp !== 2'b00) begin
            $error("Test 4: GPIO_INPUT response incorrect");
        end

        $display("Test 4 passed");


        // ========================================================
        // Test 5: GPIO_INPUT is read-only
        // ========================================================

        $display("");
        $display("Test 5: GPIO_INPUT write protection");


        // Attempt to write GPIO_INPUT

        @(posedge ACLK);

        wr_addr <= 32'h0000_0004;
        wr_data <= 32'hFFFF_FFFF;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;

        #1;

        if (wr_resp !== 2'b11) begin
            $error(
                "Test 5: GPIO_INPUT write should return DECERR"
            );
        end


        // Change external GPIO input

        gpio_input = 32'hAAAA_5555;


        // Read GPIO_INPUT again

        @(posedge ACLK);

        rd_addr <= 32'h0000_0004;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_data !== 32'hAAAA_5555) begin
            $error(
                "Test 5: GPIO_INPUT was incorrectly modified"
            );
        end

        $display("Test 5 passed");


        // ========================================================
        // Test 6: Byte write strobes
        // ========================================================

        $display("");
        $display("Test 6: GPIO_OUTPUT byte strobes");


        // First write complete value

        @(posedge ACLK);

        wr_addr <= 32'h0000_0000;
        wr_data <= 32'h1122_3344;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;


        // Modify byte 0 and byte 2 only
        //
        // Original value:
        //
        //     11 22 33 44
        //
        // WDATA:
        //
        //     00 BB 00 AA
        //
        // WSTRB:
        //
        //     0  1  0  1
        //
        // Therefore:
        //
        // byte 3 = 11  unchanged
        // byte 2 = BB  updated
        // byte 1 = 33  unchanged
        // byte 0 = AA  updated
        //
        // Expected result:
        //
        //     11 BB 33 AA
        //

        @(posedge ACLK);

        wr_addr <= 32'h0000_0000;
        wr_data <= 32'h00BB_00AA;
        wr_strb <= 4'b0101;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;

        #1;

        if (gpio_output !== 32'h11BB_33AA) begin
            $error(
                "Test 6: byte strobe result incorrect. Expected 11BB_33AA, Got %h",
                gpio_output
            );
        end

        $display("Test 6 passed");


        // ========================================================
        // Test 7: Invalid register offset
        // ========================================================

        $display("");
        $display("Test 7: Invalid register offset");


        // Invalid write

        @(posedge ACLK);

        wr_addr <= 32'h0000_0020;
        wr_data <= 32'h1234_5678;
        wr_strb <= 4'b1111;
        wr_en   <= 1'b1;

        @(posedge ACLK);

        wr_en <= 1'b0;

        #1;

        if (wr_resp !== 2'b11) begin
            $error(
                "Test 7: invalid write should return DECERR"
            );
        end


        // Invalid read

        @(posedge ACLK);

        rd_addr <= 32'h0000_0020;
        rd_en   <= 1'b1;

        @(posedge ACLK);

        rd_en <= 1'b0;

        #1;

        if (rd_resp !== 2'b11) begin
            $error(
                "Test 7: invalid read should return DECERR"
            );
        end

        if (rd_data !== 32'h0000_0000) begin
            $error(
                "Test 7: invalid read data should be zero"
            );
        end

        $display("Test 7 passed");


        // ========================================================
        // Final result
        // ========================================================

        $display("");
        $display("[PASS] GPIO slave test completed successfully");
        $display("");

        $finish;

    end

endmodule