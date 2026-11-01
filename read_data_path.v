module read_data_path #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input wire aclk,
    input wire aresetn,

    input wire [ADDR_WIDTH-1:0] ar_reg_addr,
    input wire ar_addr_valid,
    input wire arvalid,
    output wire arready,

    input wire [DATA_WIDTH-1:0] reg_rd_data,

    output reg [ADDR_WIDTH-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0] rdata,
    output reg rvalid,
    input wire rready,

    output reg rd_en,
    output reg rd_error
);

    reg ar_pending;
    reg address_valid_reg;
    reg [ADDR_WIDTH-1:0] address_reg;

    assign arready = !ar_pending;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ar_pending <= 1'b0;
            address_valid_reg <= 1'b0;
            address_reg <= 0;
            rd_addr <= 0;
            rdata <= 0;
            rvalid <= 1'b0;
            rd_en <= 1'b0;
            rd_error <= 1'b0;
        end
        else begin
            rd_en <= 1'b0;
            rd_error <= 1'b0;

            if (arvalid && arready) begin
                ar_pending <= 1'b1;
                address_reg <= ar_reg_addr;
                address_valid_reg <= ar_addr_valid;
            end

            if (ar_pending && !rvalid) begin
                rd_addr <= address_reg;

                if (address_valid_reg) begin
                    rdata <= reg_rd_data;
                    rd_en <= 1'b1;
                    rd_error <= 1'b0;
                end
                else begin
                    rdata <= {DATA_WIDTH{1'b0}};
                    rd_error <= 1'b1;
                end

                rvalid <= 1'b1;
            end

            if (rvalid && rready) begin
                rvalid <= 1'b0;
                ar_pending <= 1'b0;
            end
        end
    end

endmodule