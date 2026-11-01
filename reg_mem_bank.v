

module reg_mem_bank #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 16,
    parameter STRB_WIDTH = DATA_WIDTH / 8
)(
    input wire aclk,
    input wire aresetn,

    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [DATA_WIDTH-1:0] wr_data,
    input wire [STRB_WIDTH-1:0] wr_strb,

    input wire [ADDR_WIDTH-1:0] rd_addr,
    output wire [DATA_WIDTH-1:0] rd_data
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;
    integer j;

    // Asynchronous active-low reset
    // Synchronous write with byte strobes
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= {DATA_WIDTH{1'b0}};
        end
        else if (wr_en) begin
            for (j = 0; j < STRB_WIDTH; j = j + 1) begin
                if (wr_strb[j])
                    mem[wr_addr][8*j +: 8]
                        <= wr_data[8*j +: 8];
            end
        end
    end

    // Asynchronous read
    assign rd_data = aresetn ?
                     mem[rd_addr] :
                     {DATA_WIDTH{1'b0}};

endmodule
