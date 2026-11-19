`timescale 1ns/1ps

module read_data_path #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  wire                  aclk,
    input  wire                  aresetn,

    // Address decoder outputs
    input  wire [ADDR_WIDTH-1:0] ar_reg_addr,
    input  wire                  ar_addr_valid,

    // AXI read address channel
    input  wire                  arvalid,
    output wire                  arready,

    // Register bank read interface
    input  wire [DATA_WIDTH-1:0] reg_rd_data,
    output wire [ADDR_WIDTH-1:0] rd_addr,
    output reg                   rd_en,

    // AXI read data channel
    output reg  [DATA_WIDTH-1:0] rdata,
    output reg                   rvalid,
    input  wire                  rready,

    // Status
    output reg                   rd_error
);

    reg ar_pending;
    reg address_valid_reg;
    reg [ADDR_WIDTH-1:0] address_reg;

    assign arready = !ar_pending;

    // Combinational read address ensures reg_mem_bank outputs valid data
    // before rdata samples it on the rising clock edge
    assign rd_addr = ar_pending ? address_reg : ar_reg_addr;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ar_pending        <= 1'b0;
            address_valid_reg <= 1'b0;
            address_reg       <= {ADDR_WIDTH{1'b0}};
            rdata             <= {DATA_WIDTH{1'b0}};
            rvalid            <= 1'b0;
            rd_en             <= 1'b0;
            rd_error          <= 1'b0;
        end
        else begin
            rd_en <= 1'b0;

            // Capture incoming read address handshake
            if (arvalid && arready) begin
                ar_pending        <= 1'b1;
                address_reg       <= ar_reg_addr;
                address_valid_reg <= ar_addr_valid;
            end

            // Drive read data and valid flag
            if (ar_pending && !rvalid) begin
                if (address_valid_reg) begin
                    rdata    <= reg_rd_data;
                    rd_en    <= 1'b1;
                    rd_error <= 1'b0;
                end
                else begin
                    rdata    <= {DATA_WIDTH{1'b0}};
                    rd_error <= 1'b1; // Slave error (SLVERR) on invalid/unaligned address
                end
                rvalid <= 1'b1;
            end

            // Clear on master acceptance
            if (rvalid && rready) begin
                rvalid     <= 1'b0;
                ar_pending <= 1'b0;
            end
        end
    end

endmodule
