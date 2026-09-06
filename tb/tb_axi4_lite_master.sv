`timescale 1ns/1ps

module tb_axi4_lite_master;

    // ============================================================
    // Clock and reset
    // ============================================================

    logic ACLK;
    logic ARESETn;


    // ============================================================
    // User-side write interface
    // ============================================================

    logic [31:0] write_addr;
    logic [31:0] write_data;
    logic [3:0]  write_strb;
    logic        write_valid;
    logic        write_ready;

    logic [1:0]  write_resp;
    logic        write_resp_valid;


    // ============================================================
    // User-side read interface
    // ============================================================

    logic [31:0] read_addr;
    logic        read_valid;
    logic        read_ready;

    logic [31:0] read_data;
    logic [1:0]  read_resp;
    logic        read_resp_valid;


    // ============================================================
    // AXI interface
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
    // DUT
    // ============================================================

    axi4_lite_master dut (

        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .write_addr(write_addr),
        .write_data(write_data),
        .write_strb(write_strb),
        .write_valid(write_valid),
        .write_ready(write_ready),

        .write_resp(write_resp),
        .write_resp_valid(write_resp_valid),

        .read_addr(read_addr),
        .read_valid(read_valid),
        .read_ready(read_ready),

        .read_data(read_data),
        .read_resp(read_resp),
        .read_resp_valid(read_resp_valid),

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
        .M_RREADY(M_RREADY)

    );


    // ============================================================
    // Clock
    // ============================================================

    initial begin

        ACLK = 1'b0;

        forever #5 ACLK = ~ACLK;

    end


    // ============================================================
    // Initial AXI slave signals
    // ============================================================

    initial begin

        M_AWREADY = 1'b0;
        M_WREADY  = 1'b0;

        M_BRESP   = 2'b00;
        M_BVALID  = 1'b0;

        M_ARREADY = 1'b0;

        M_RDATA   = 32'h0;
        M_RRESP   = 2'b00;
        M_RVALID  = 1'b0;

    end


    // ============================================================
    // Reset
    // ============================================================

    initial begin

        ARESETn = 1'b0;

        write_addr  = '0;
        write_data  = '0;
        write_strb  = '0;
        write_valid = 1'b0;

        read_addr  = '0;
        read_valid = 1'b0;

        #20;

        ARESETn = 1'b1;

    end


    // ============================================================
    // Test sequence
    // ============================================================

    initial begin

        $display("==============================================");
        $display(" AXI4-Lite Master Testbench");
        $display("==============================================");


        wait (ARESETn == 1'b1);

        // --------------------------------------------------------
        // WRITE TRANSACTION
        // --------------------------------------------------------

        @(posedge ACLK);

        write_addr  <= 32'h0000_1000;
        write_data  <= 32'hDEAD_BEEF;
        write_strb  <= 4'b1111;
        write_valid <= 1'b1;

        @(posedge ACLK);

        wait (write_ready == 1'b0);

        write_valid <= 1'b0;

        $display("Write transaction accepted");


        // --------------------------------------------------------
        // AXI write address handshake
        // --------------------------------------------------------

        wait (M_AWVALID == 1'b1);

        if (M_AWADDR !== 32'h0000_1000) begin
            $error("Incorrect AWADDR");
        end

        M_AWREADY <= 1'b1;

        @(posedge ACLK);

        M_AWREADY <= 1'b0;

        $display("Write address handshake completed");


        // --------------------------------------------------------
        // AXI write data handshake
        // --------------------------------------------------------

        wait (M_WVALID == 1'b1);

        if (M_WDATA !== 32'hDEAD_BEEF) begin
            $error("Incorrect WDATA");
        end

        if (M_WSTRB !== 4'b1111) begin
            $error("Incorrect WSTRB");
        end

        M_WREADY <= 1'b1;

        @(posedge ACLK);

        M_WREADY <= 1'b0;

        $display("Write data handshake completed");


        // --------------------------------------------------------
        // Write response
        // --------------------------------------------------------

        wait (M_BREADY == 1'b1);

        M_BRESP  <= 2'b00;
        M_BVALID <= 1'b1;

        @(posedge ACLK);

        M_BVALID <= 1'b0;

        wait (write_resp_valid == 1'b1);

        if (write_resp !== 2'b00) begin
            $error("Incorrect write response");
        end

        $display("Write response received");


        // --------------------------------------------------------
        // READ TRANSACTION
        // --------------------------------------------------------

        @(posedge ACLK);

        read_addr  <= 32'h0000_2000;
        read_valid <= 1'b1;

        @(posedge ACLK);

        wait (read_ready == 1'b0);

        read_valid <= 1'b0;

        $display("Read transaction accepted");


        // --------------------------------------------------------
        // AXI read address handshake
        // --------------------------------------------------------

        wait (M_ARVALID == 1'b1);

        if (M_ARADDR !== 32'h0000_2000) begin
            $error("Incorrect ARADDR");
        end

        M_ARREADY <= 1'b1;

        @(posedge ACLK);

        M_ARREADY <= 1'b0;

        $display("Read address handshake completed");


        // --------------------------------------------------------
        // Read data
        // --------------------------------------------------------

        wait (M_RREADY == 1'b1);

        M_RDATA  <= 32'h1234_5678;
        M_RRESP  <= 2'b00;
        M_RVALID <= 1'b1;

        @(posedge ACLK);

        M_RVALID <= 1'b0;

        wait (read_resp_valid == 1'b1);

        if (read_data !== 32'h1234_5678) begin
            $error("Incorrect read data");
        end

        if (read_resp !== 2'b00) begin
            $error("Incorrect read response");
        end

        $display("Read data received");


        // --------------------------------------------------------
        // PASS
        // --------------------------------------------------------

        $display("");
        $display("[PASS] AXI4-Lite master test completed successfully");
        $display("");

        $finish;

    end

endmodule