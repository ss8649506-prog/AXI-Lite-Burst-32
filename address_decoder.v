
module address_decoder #(
    parameter ADDR_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 4,
    parameter BASE_ADDR = 32'h40000000
)(
    input wire [ADDR_WIDTH-1:0] addr,

    output wire [REG_ADDR_WIDTH-1:0] reg_addr,
    output wire addr_valid
);

    wire address_aligned;
    wire address_in_range;

    assign address_aligned = (addr[1:0] == 2'b00);

    assign address_in_range =
        (addr[ADDR_WIDTH-1:6] ==
         BASE_ADDR[ADDR_WIDTH-1:6]);

    assign addr_valid = address_aligned & address_in_range;

    assign reg_addr = addr[5:2];

endmodule
