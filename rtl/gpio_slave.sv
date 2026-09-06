module gpio_slave #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input  logic                     ACLK,
    input  logic                     ARESETn,

    // Write interface from AXI4-Lite slave
    input  logic                     wr_en,
    input  logic [ADDR_WIDTH-1:0]    wr_addr,
    input  logic [DATA_WIDTH-1:0]    wr_data,
    input  logic [DATA_WIDTH/8-1:0]  wr_strb,
    output logic [1:0]               wr_resp,

    // Read interface from AXI4-Lite slave
    input  logic                     rd_en,
    input  logic [ADDR_WIDTH-1:0]    rd_addr,
    output logic [DATA_WIDTH-1:0]    rd_data,
    output logic [1:0]               rd_resp,

    // External GPIO pins
    input  logic [DATA_WIDTH-1:0]    gpio_input,
    output logic [DATA_WIDTH-1:0]    gpio_output,
    output logic [DATA_WIDTH-1:0]    gpio_direction
);

    // GPIO register offsets
    localparam logic [ADDR_WIDTH-1:0] GPIO_OUTPUT_OFFSET    = 32'h0000_0000;
    localparam logic [ADDR_WIDTH-1:0] GPIO_INPUT_OFFSET     = 32'h0000_0004;
    localparam logic [ADDR_WIDTH-1:0] GPIO_DIRECTION_OFFSET = 32'h0000_0008;

    localparam logic [1:0] AXI_OKAY   = 2'b00;
    localparam logic [1:0] AXI_DECERR = 2'b11;

    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    /*
     * Apply AXI byte strobes to a 32-bit register.
     *
     * WSTRB[0] controls bits [7:0]
     * WSTRB[1] controls bits [15:8]
     * WSTRB[2] controls bits [23:16]
     * WSTRB[3] controls bits [31:24]
     */

task automatic apply_wstrb(
    output logic [DATA_WIDTH-1:0] new_value,
    input  logic [DATA_WIDTH-1:0] current_value,
    input  logic [DATA_WIDTH-1:0] data,
    input  logic [STRB_WIDTH-1:0] strb
);
    integer i;
    begin
        new_value = current_value;

        for (i = 0; i < STRB_WIDTH; i = i + 1) begin
            if (strb[i])
                new_value[i*8 +: 8] = data[i*8 +: 8];
        end
    end
endtask

    /*
     * Write logic
     */

logic [DATA_WIDTH-1:0] gpio_output_next;
logic [DATA_WIDTH-1:0] gpio_direction_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            gpio_output    <= '0;
            gpio_direction <= '0;
            wr_resp        <= AXI_OKAY;
        end
        else begin
            if (wr_en) begin

                case (wr_addr[ADDR_WIDTH-1:0])

                    GPIO_OUTPUT_OFFSET: begin
apply_wstrb(
    gpio_output_next,
    gpio_output,
    wr_data,
    wr_strb
);

gpio_output <= gpio_output_next;
                        wr_resp <= AXI_OKAY;
                    end

                    GPIO_DIRECTION_OFFSET: begin
apply_wstrb(
    gpio_direction_next,
    gpio_direction,
    wr_data,
    wr_strb
);

gpio_direction <= gpio_direction_next;
                        wr_resp <= AXI_OKAY;
                    end

                    GPIO_INPUT_OFFSET: begin
                        // GPIO_INPUT is read-only.
                        wr_resp <= AXI_DECERR;
                    end

                    default: begin
                        // Invalid GPIO register offset.
                        wr_resp <= AXI_DECERR;
                    end

                endcase
            end
        end
    end

    /*
     * Read logic
     */
    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            rd_data <= '0;
            rd_resp <= AXI_OKAY;
        end
        else begin
            if (rd_en) begin

                case (rd_addr[ADDR_WIDTH-1:0])

                    GPIO_OUTPUT_OFFSET: begin
                        rd_data <= gpio_output;
                        rd_resp <= AXI_OKAY;
                    end

                    GPIO_INPUT_OFFSET: begin
                        rd_data <= gpio_input;
                        rd_resp <= AXI_OKAY;
                    end

                    GPIO_DIRECTION_OFFSET: begin
                        rd_data <= gpio_direction;
                        rd_resp <= AXI_OKAY;
                    end

                    default: begin
                        rd_data <= '0;
                        rd_resp <= AXI_DECERR;
                    end

                endcase
            end
        end
    end

endmodule
