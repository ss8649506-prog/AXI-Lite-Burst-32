module low_power_controller #(
    parameter IDLE_COUNT_WIDTH = 8,
    parameter IDLE_THRESHOLD = 8'd10
)(
    input wire aclk,
    input wire aresetn,
    input wire busy,
    output reg low_power_enable
);

    reg [IDLE_COUNT_WIDTH-1:0] idle_count;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            idle_count      <= {IDLE_COUNT_WIDTH{1'b0}};
            low_power_enable <= 1'b0;
        end
        else begin
            if (busy) begin
                idle_count      <= {IDLE_COUNT_WIDTH{1'b0}};
                low_power_enable <= 1'b0;
            end
            else if (!low_power_enable) begin
                if (idle_count < IDLE_THRESHOLD)
                    idle_count <= idle_count + 1'b1;

                if (idle_count >= IDLE_THRESHOLD - 1'b1)
                    low_power_enable <= 1'b1;
            end
        end
    end

endmodule