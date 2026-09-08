module axi4_lite_addr_decoder #(
    parameter int ADDR_WIDTH = 32
)(
    input  logic [ADDR_WIDTH-1:0] addr,

    output logic                  ram_sel,
    output logic                  gpio_sel,
    output logic                  decerr
);

    // ============================================================
    // Address Map
    // ============================================================

    localparam logic [ADDR_WIDTH-1:0] RAM_LAST  = 32'h0000_03FF;
    localparam logic [ADDR_WIDTH-1:0] GPIO_BASE = 32'h0000_1000;
    localparam logic [ADDR_WIDTH-1:0] GPIO_LAST = 32'h0000_10FF;


    // ============================================================
    // Address Decode
    // ============================================================

    always_comb begin

        // Default values
        ram_sel  = 1'b0;
        gpio_sel = 1'b0;
        decerr   = 1'b0;


        // --------------------------------------------------------
        // RAM
        // --------------------------------------------------------

if (addr <= RAM_LAST) begin
            ram_sel = 1'b1;

        end


        // --------------------------------------------------------
        // GPIO
        // --------------------------------------------------------

        else if ((addr >= GPIO_BASE) && (addr <= GPIO_LAST)) begin

            gpio_sel = 1'b1;

        end


        // --------------------------------------------------------
        // Unmapped address
        // --------------------------------------------------------

        else begin

            decerr = 1'b1;

        end

    end

endmodule
