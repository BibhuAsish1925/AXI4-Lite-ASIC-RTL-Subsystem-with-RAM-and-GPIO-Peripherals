`timescale 1ns/1ps

module tb_axi4_lite_top;

    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;

    logic ACLK;
    logic ARESETn;

    // ------------------------------------------------------------
    // User interface
    // ------------------------------------------------------------

    logic [ADDR_WIDTH-1:0]   write_addr;
    logic [DATA_WIDTH-1:0]   write_data;
    logic [DATA_WIDTH/8-1:0] write_strb;
    logic                    write_valid;
    logic                    write_ready;
    logic [1:0]              write_resp;
    logic                    write_resp_valid;

    logic [ADDR_WIDTH-1:0]   read_addr;
    logic                    read_valid;
    logic                    read_ready;
    logic [DATA_WIDTH-1:0]   read_data;
    logic [1:0]              read_resp;
    logic                    read_resp_valid;

    // ------------------------------------------------------------
    // GPIO
    // ------------------------------------------------------------

    logic [DATA_WIDTH-1:0] gpio_input;
    logic [DATA_WIDTH-1:0] gpio_output;
    logic [DATA_WIDTH-1:0] gpio_direction;

    integer errors;


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        ACLK = 1'b0;
        forever #5 ACLK = ~ACLK;
    end


    // ============================================================
    // DUT
    // ============================================================

    axi4_lite_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
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

        .gpio_input       (gpio_input),
        .gpio_output      (gpio_output),
        .gpio_direction   (gpio_direction)
    );


    // ============================================================
    // WRITE TASK
    // ============================================================

    task automatic axi_write(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [3:0]  strb,
        input logic [1:0]  expected_resp
    );

        begin

            @(negedge ACLK);

            write_addr  = addr;
            write_data  = data;
            write_strb  = strb;
            write_valid = 1'b1;

            wait(write_ready);

            @(posedge ACLK);

            @(negedge ACLK);
            write_valid = 1'b0;

            wait(write_resp_valid);

            #1;

            if (write_resp !== expected_resp) begin
                $display(
                    "ERROR: WRITE addr=%h data=%h resp=%b expected=%b",
                    addr,
                    data,
                    write_resp,
                    expected_resp
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "WRITE PASS: addr=%h data=%h resp=%b",
                    addr,
                    data,
                    write_resp
                );
            end

        end

    endtask


    // ============================================================
    // READ TASK
    // ============================================================

    task automatic axi_read(
        input logic [31:0] addr,
        input logic [31:0] expected_data,
        input logic [1:0]  expected_resp
    );

        begin

            @(negedge ACLK);

            read_addr  = addr;
            read_valid = 1'b1;

            wait(read_ready);

            @(posedge ACLK);

            @(negedge ACLK);
            read_valid = 1'b0;

            wait(read_resp_valid);

            #1;

            if (read_data !== expected_data) begin
                $display(
                    "ERROR: READ addr=%h data=%h expected=%h",
                    addr,
                    read_data,
                    expected_data
                );
                errors = errors + 1;
            end

            if (read_resp !== expected_resp) begin
                $display(
                    "ERROR: READ addr=%h resp=%b expected=%b",
                    addr,
                    read_resp,
                    expected_resp
                );
                errors = errors + 1;
            end

            if (
                (read_data === expected_data) &&
                (read_resp === expected_resp)
            ) begin
                $display(
                    "READ PASS: addr=%h data=%h resp=%b",
                    addr,
                    read_data,
                    read_resp
                );
            end

        end

    endtask


    // ============================================================
    // TEST SEQUENCE
    // ============================================================

    initial begin

        errors = 0;

        write_addr  = '0;
        write_data  = '0;
        write_strb  = '0;
        write_valid = 1'b0;

        read_addr   = '0;
        read_valid  = 1'b0;

        gpio_input  = 32'h1234_5678;


        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        ARESETn = 1'b0;

        repeat (4)
            @(posedge ACLK);

        ARESETn = 1'b1;

        repeat (2)
            @(posedge ACLK);


        $display("");
        $display("==============================================");
        $display(" AXI4-Lite TOP LEVEL TESTBENCH");
        $display("==============================================");


        // --------------------------------------------------------
        // TEST 1
        // RAM WRITE
        // --------------------------------------------------------

        $display("");
        $display("Test 1: RAM write");

        axi_write(
            32'h0000_0000,
            32'hDEAD_BEEF,
            4'b1111,
            2'b00
        );


        // --------------------------------------------------------
        // TEST 2
        // RAM READ
        // --------------------------------------------------------

        $display("");
        $display("Test 2: RAM read");

        axi_read(
            32'h0000_0000,
            32'hDEAD_BEEF,
            2'b00
        );


        // --------------------------------------------------------
        // TEST 3
        // RAM BYTE STROBE
        // --------------------------------------------------------

        $display("");
        $display("Test 3: RAM byte strobes");

        axi_write(
            32'h0000_0004,
            32'h1122_3344,
            4'b1111,
            2'b00
        );

        axi_write(
            32'h0000_0004,
            32'h00BB_00AA,
            4'b0101,
            2'b00
        );

        axi_read(
            32'h0000_0004,
            32'h11BB_33AA,
            2'b00
        );


        // --------------------------------------------------------
        // TEST 4
        // GPIO OUTPUT
        //
        // This specifically checks GPIO address translation:
        // 0x1000 -> offset 0x00
        // --------------------------------------------------------

        $display("");
        $display("Test 4: GPIO output");

        axi_write(
            32'h0000_1000,
            32'hA5A5_5A5A,
            4'b1111,
            2'b00
        );

        axi_read(
            32'h0000_1000,
            32'hA5A5_5A5A,
            2'b00
        );


        // --------------------------------------------------------
        // TEST 5
        // GPIO DIRECTION
        //
        // 0x1008 -> offset 0x08
        // --------------------------------------------------------

        $display("");
        $display("Test 5: GPIO direction");

        axi_write(
            32'h0000_1008,
            32'hFFFF_0000,
            4'b1111,
            2'b00
        );

        axi_read(
            32'h0000_1008,
            32'hFFFF_0000,
            2'b00
        );


        // --------------------------------------------------------
        // TEST 6
        // GPIO INPUT
        //
        // 0x1004 -> offset 0x04
        // --------------------------------------------------------

        $display("");
        $display("Test 6: GPIO input");

        axi_read(
            32'h0000_1004,
            32'h1234_5678,
            2'b00
        );


        // --------------------------------------------------------
        // TEST 7
        // GPIO BYTE STROBES
        // --------------------------------------------------------

        $display("");
        $display("Test 7: GPIO byte strobes");

        axi_write(
            32'h0000_1000,
            32'h1122_3344,
            4'b1111,
            2'b00
        );

        axi_write(
            32'h0000_1000,
            32'h00BB_00AA,
            4'b0101,
            2'b00
        );

        axi_read(
            32'h0000_1000,
            32'h11BB_33AA,
            2'b00
        );


        // --------------------------------------------------------
        // TEST 8
        // UNMAPPED WRITE
        // --------------------------------------------------------

        $display("");
        $display("Test 8: Unmapped write");

        axi_write(
            32'h0000_2000,
            32'hCAFE_BABE,
            4'b1111,
            2'b11
        );


        // --------------------------------------------------------
        // TEST 9
        // UNMAPPED READ
        // --------------------------------------------------------

        $display("");
        $display("Test 9: Unmapped read");

        axi_read(
            32'h0000_2000,
            32'h0000_0000,
            2'b11
        );


        // --------------------------------------------------------
        // TEST 10
        // INVALID GPIO REGISTER
        // 0x100C is inside GPIO address range but undefined.
        // --------------------------------------------------------

        $display("");
        $display("Test 10: Invalid GPIO register");

        axi_write(
            32'h0000_100C,
            32'hFFFF_FFFF,
            4'b1111,
            2'b11
        );

        axi_read(
            32'h0000_100C,
            32'h0000_0000,
            2'b11
        );


        // --------------------------------------------------------
        // TEST 11
        // RAM LAST WORD
        // --------------------------------------------------------

        $display("");
        $display("Test 11: RAM last word");

        axi_write(
            32'h0000_03FC,
            32'h55AA_1234,
            4'b1111,
            2'b00
        );

        axi_read(
            32'h0000_03FC,
            32'h55AA_1234,
            2'b00
        );


        // --------------------------------------------------------
        // FINAL RESULT
        // --------------------------------------------------------

        $display("");
        $display("==============================================");

        if (errors == 0) begin
            $display("[PASS] AXI4-Lite top-level test completed successfully");
        end
        else begin
            $display(
                "[FAIL] AXI4-Lite top-level test completed with %0d errors",
                errors
            );
        end

        $display("==============================================");

        #20;
        $finish;

    end

endmodule