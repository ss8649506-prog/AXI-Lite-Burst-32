module burst_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LEN_WIDTH  = 8
)(
    input wire aclk,
    input wire aresetn,

    input wire start,
    input wire write_mode,
    input wire [ADDR_WIDTH-1:0] start_addr,
    input wire [LEN_WIDTH-1:0] burst_len,

    output reg [ADDR_WIDTH-1:0] current_addr,
    output reg [LEN_WIDTH-1:0] beat_count,
    output reg burst_active,
    output reg burst_done,

    output reg axi_valid,
    input wire axi_ready
);

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            current_addr <= {ADDR_WIDTH{1'b0}};
            beat_count   <= {LEN_WIDTH{1'b0}};
            burst_active <= 1'b0;
            burst_done   <= 1'b0;
            axi_valid    <= 1'b0;
        end
        else begin
            burst_done <= 1'b0;

            if (start && !burst_active) begin
                current_addr <= start_addr;
                beat_count   <= burst_len;
                burst_active <= (burst_len != 0);
                axi_valid    <= (burst_len != 0);
            end
            else if (burst_active && axi_valid && axi_ready) begin
                if (beat_count <= 1) begin
                    beat_count   <= 0;
                    burst_active <= 1'b0;
                    axi_valid    <= 1'b0;
                    burst_done   <= 1'b1;
                end
                else begin
                    beat_count   <= beat_count - 1'b1;
                    current_addr <= current_addr + (DATA_WIDTH / 8);
                end
            end
        end
    end

endmodule