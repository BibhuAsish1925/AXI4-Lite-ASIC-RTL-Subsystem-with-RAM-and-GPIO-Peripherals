`timescale 1ns/1ps

module tb_axi4_lite_addr_decoder;

    logic [31:0] addr;

    logic        ram_sel;
    logic        gpio_sel;
    logic        decerr;


    // ============================================================
    // DUT
    // ============================================================

    axi4_lite_addr_decoder dut (

        .addr(addr),

        .ram_sel(ram_sel),
        .gpio_sel(gpio_sel),
        .decerr(decerr)

    );


    // ============================================================
    // Test helper
    // ============================================================

    task automatic check_address(
        input logic [31:0] test_addr,
        input logic        expected_ram,
        input logic        expected_gpio,
        input logic        expected_decerr
    );

        begin

            addr = test_addr;

            #1;

            if (ram_sel !== expected_ram) begin
                $error(
                    "Address %h: RAM select incorrect. Expected %b, Got %b",
                    test_addr,
                    expected_ram,
                    ram_sel
                );
            end

            if (gpio_sel !== expected_gpio) begin
                $error(
                    "Address %h: GPIO select incorrect. Expected %b, Got %b",
                    test_addr,
                    expected_gpio,
                    gpio_sel
                );
            end

            if (decerr !== expected_decerr) begin
                $error(
                    "Address %h: DECERR incorrect. Expected %b, Got %b",
                    test_addr,
                    expected_decerr,
                    decerr
                );
            end

        end

    endtask


    // ============================================================
    // Test sequence
    // ============================================================

    initial begin

        $display("==============================================");
        $display(" AXI4-Lite Address Decoder Testbench");
        $display("==============================================");


        // ========================================================
        // RAM tests
        // ========================================================

        $display("");
        $display("Testing RAM address range...");

        check_address(
            32'h0000_0000,
            1'b1,
            1'b0,
            1'b0
        );

        check_address(
            32'h0000_0100,
            1'b1,
            1'b0,
            1'b0
        );

        check_address(
            32'h0000_03FF,
            1'b1,
            1'b0,
            1'b0
        );


        // ========================================================
        // RAM boundary
        // ========================================================

        $display("Testing RAM boundary...");

        check_address(
            32'h0000_0400,
            1'b0,
            1'b0,
            1'b1
        );


        // ========================================================
        // GPIO tests
        // ========================================================

        $display("");
        $display("Testing GPIO address range...");

        check_address(
            32'h0000_1000,
            1'b0,
            1'b1,
            1'b0
        );

        check_address(
            32'h0000_1050,
            1'b0,
            1'b1,
            1'b0
        );

        check_address(
            32'h0000_10FF,
            1'b0,
            1'b1,
            1'b0
        );


        // ========================================================
        // GPIO boundary
        // ========================================================

        $display("Testing GPIO boundaries...");

        check_address(
            32'h0000_0FFF,
            1'b0,
            1'b0,
            1'b1
        );

        check_address(
            32'h0000_1100,
            1'b0,
            1'b0,
            1'b1
        );


        // ========================================================
        // Other unmapped addresses
        // ========================================================

        $display("");
        $display("Testing unmapped addresses...");

        check_address(
            32'h0000_2000,
            1'b0,
            1'b0,
            1'b1
        );

        check_address(
            32'hFFFF_FFFF,
            1'b0,
            1'b0,
            1'b1
        );


        // ========================================================
        // PASS
        // ========================================================

        $display("");
        $display("[PASS] AXI4-Lite address decoder test completed successfully");
        $display("");

        $finish;

    end

endmodule