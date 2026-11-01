`timescale 1ns/1ps

module tb_burst_controller;

    reg aclk;
    reg aresetn;

    reg start;
    reg write_mode;
    reg [31:0] start_addr;
    reg [7:0] burst_len;

    wire [31:0] current_addr;
    wire [7:0] beat_count;
    wire burst_active;
    wire burst_done;

    wire axi_valid;
    reg axi_ready;

    integer checks;

    burst_controller uut (
        .aclk(aclk),
        .aresetn(aresetn),
        .start(start),
        .write_mode(write_mode),
        .start_addr(start_addr),
        .burst_len(burst_len),
        .current_addr(current_addr),
        .beat_count(beat_count),
        .burst_active(burst_active),
        .burst_done(burst_done),
        .axi_valid(axi_valid),
        .axi_ready(axi_ready)
    );

    always #5 aclk = ~aclk;

    initial begin
        aclk = 0;
        aresetn = 0;
        start = 0;
        write_mode = 1;
        start_addr = 32'h40000000;
        burst_len = 4;
        axi_ready = 0;
        checks = 0;

        repeat(2) @(negedge aclk);
        aresetn = 1;

        // Start four-beat burst
        @(negedge aclk);
        start = 1;

        @(negedge aclk);
        start = 0;
        #1;

        if (!burst_active || !axi_valid ||
            current_addr !== 32'h40000000 ||
            beat_count !== 4)
            $fatal(1, "FAIL: Burst start");
        else begin
            $display("PASS: Burst start");
            checks = checks + 1;
        end

        // Accept beat 1
        @(negedge aclk);
        axi_ready = 1;

        @(negedge aclk);
        #1;
        if (current_addr !== 32'h40000004 || beat_count !== 3)
            $fatal(1, "FAIL: Beat 1");
        else begin
            $display("PASS: Beat 1");
            checks = checks + 1;
        end

        // Accept beat 2
        @(negedge aclk);
        #1;
        if (current_addr !== 32'h40000008 || beat_count !== 2)
            $fatal(1, "FAIL: Beat 2");
        else begin
            $display("PASS: Beat 2");
            checks = checks + 1;
        end

        // Accept beat 3
        @(negedge aclk);
        #1;
        if (current_addr !== 32'h4000000C || beat_count !== 1)
            $fatal(1, "FAIL: Beat 3");
        else begin
            $display("PASS: Beat 3");
            checks = checks + 1;
        end

        // Accept final beat
        @(negedge aclk);
        #1;
        if (burst_active || axi_valid || !burst_done)
            $fatal(1, "FAIL: Burst completion");
        else begin
            $display("PASS: Burst completion");
            checks = checks + 1;
        end

        $display("ALL BURST CONTROLLER TESTS PASSED");
        $display("Total checks = %0d", checks);
        $finish;
    end

endmodule