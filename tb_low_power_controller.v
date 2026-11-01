`timescale 1ns/1ps

module tb_low_power_controller;

    reg aclk;
    reg aresetn;
    reg busy;
    wire low_power_enable;

    integer checks;

    low_power_controller #(
        .IDLE_COUNT_WIDTH(8),
        .IDLE_THRESHOLD(8'd4)
    ) uut (
        .aclk(aclk),
        .aresetn(aresetn),
        .busy(busy),
        .low_power_enable(low_power_enable)
    );

    always #5 aclk = ~aclk;

    initial begin
        aclk = 0;
        aresetn = 0;
        busy = 0;
        checks = 0;

        repeat(2) @(negedge aclk);
        aresetn = 1;

        // Wait for idle threshold
        repeat(4) @(negedge aclk);
        #1;

        if (low_power_enable !== 1'b1)
            $fatal(1, "FAIL: Low power did not enable");
        else begin
            $display("PASS: Low power enabled after idle");
            checks = checks + 1;
        end

        // Activity should disable low power
        @(negedge aclk);
        busy = 1;
        @(negedge aclk);
        #1;

        if (low_power_enable !== 1'b0)
            $fatal(1, "FAIL: Low power did not disable");
        else begin
            $display("PASS: Low power disabled during activity");
            checks = checks + 1;
        end

        // Return to idle
        @(negedge aclk);
        busy = 0;
        repeat(4) @(negedge aclk);
        #1;

        if (low_power_enable !== 1'b1)
            $fatal(1, "FAIL: Low power did not re-enable");
        else begin
            $display("PASS: Low power re-enabled after idle");
            checks = checks + 1;
        end

        $display("ALL LOW POWER CONTROLLER TESTS PASSED");
        $display("Total checks = %0d", checks);
        $finish;
    end

endmodule