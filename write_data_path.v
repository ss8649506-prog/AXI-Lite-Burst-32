
module write_data_path #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH / 8
)(
    input wire aclk,
    input wire aresetn,

    // Address decoder outputs
    input wire [ADDR_WIDTH-1:0] aw_reg_addr,
    input wire aw_addr_valid,

    // AXI write address channel
    input wire awvalid,
    output wire awready,

    // AXI write data channel
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [STRB_WIDTH-1:0] wstrb,
    input wire wvalid,
    output wire wready,

    // Register bank write interface
    output wire wr_en,
    output wire [ADDR_WIDTH-1:0] wr_addr,
    output wire [DATA_WIDTH-1:0] wr_data,
    output wire [STRB_WIDTH-1:0] wr_strb,

    // Transaction status
    output wire wr_done,
    output wire wr_error
);

    reg aw_pending;
    reg w_pending;

    reg [ADDR_WIDTH-1:0] address_reg;
    reg address_valid_reg;

    reg [DATA_WIDTH-1:0] data_reg;
    reg [STRB_WIDTH-1:0] strobe_reg;

    // AXI channel ready signals
    assign awready = !aw_pending;
    assign wready  = !w_pending;

    // Both write channels accepted
    assign wr_done = aw_pending && w_pending;

    // Register bank write enable
    assign wr_en = wr_done && address_valid_reg;

    // Invalid address indication
    assign wr_error = wr_done && !address_valid_reg;

    // Register bank outputs
    assign wr_addr = address_reg;
    assign wr_data = data_reg;
    assign wr_strb = strobe_reg;

    // Capture write address and write data independently
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            aw_pending        <= 1'b0;
            w_pending         <= 1'b0;
            address_reg       <= {ADDR_WIDTH{1'b0}};
            address_valid_reg <= 1'b0;
            data_reg          <= {DATA_WIDTH{1'b0}};
            strobe_reg        <= {STRB_WIDTH{1'b0}};
        end
        else begin

            if (wr_done) begin
                aw_pending <= 1'b0;
                w_pending  <= 1'b0;
            end
            else begin

                if (awvalid && awready) begin
                    aw_pending        <= 1'b1;
                    address_reg       <= aw_reg_addr;
                    address_valid_reg <= aw_addr_valid;
                end

                if (wvalid && wready) begin
                    w_pending  <= 1'b1;
                    data_reg  <= wdata;
                    strobe_reg <= wstrb;
                end

            end
        end
    end

endmodule
