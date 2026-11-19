`timescale 1ns/1ps

module address_decoder #(
    parameter ADDR_WIDTH     = 32,
    parameter REG_ADDR_WIDTH = 4,
    parameter BASE_ADDR      = 32'h40000000
)(
    input  wire [ADDR_WIDTH-1:0]     addr,
    output wire [REG_ADDR_WIDTH-1:0] reg_addr,
    output wire                      addr_valid
);

    localparam TOTAL_ADDR_BITS = REG_ADDR_WIDTH + 2; // Word offset is 2 bits for 32-bit (4 bytes)

    wire address_aligned;
    wire address_in_range;

    // Word alignment check (lower 2 bits must be 00 for 32-bit data)
    assign address_aligned = (addr[1:0] == 2'b00);

    // Check if the address falls within the base address range
    assign address_in_range = (addr[ADDR_WIDTH-1:TOTAL_ADDR_BITS] == BASE_ADDR[ADDR_WIDTH-1:TOTAL_ADDR_BITS]);

    // Valid if aligned and in range
    assign addr_valid = address_aligned & address_in_range;

    // Extract register index (word address)
    assign reg_addr = addr[TOTAL_ADDR_BITS-1:2];

endmodule
