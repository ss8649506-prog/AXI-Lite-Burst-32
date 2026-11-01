module response_logic (
    input wire aclk,
    input wire aresetn,

    input wire wr_done,
    input wire wr_error,
    output reg bvalid,
    input wire bready,
    output reg [1:0] bresp,

    input wire rd_done,
    input wire rd_error,
    output reg rvalid,
    input wire rready,
    output reg [1:0] rresp
);

    localparam RESP_OKAY  = 2'b00;
    localparam RESP_SLVERR = 2'b10;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            bvalid <= 1'b0;
            bresp  <= RESP_OKAY;
            rvalid <= 1'b0;
            rresp  <= RESP_OKAY;
        end
        else begin
            // Write response
            if (wr_done && !bvalid) begin
                bvalid <= 1'b1;

                if (wr_error)
                    bresp <= RESP_SLVERR;
                else
                    bresp <= RESP_OKAY;
            end
            else if (bvalid && bready) begin
                bvalid <= 1'b0;
            end

            // Read response
            if (rd_done && !rvalid) begin
                rvalid <= 1'b1;

                if (rd_error)
                    rresp <= RESP_SLVERR;
                else
                    rresp <= RESP_OKAY;
            end
            else if (rvalid && rready) begin
                rvalid <= 1'b0;
            end
        end
    end

endmodule