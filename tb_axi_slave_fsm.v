`timescale 1ns/1ps

module tb_axi_slave_fsm;

    reg aclk;
    reg aresetn;

    reg awvalid, awready;
    reg wvalid, wready;
    reg bvalid, bready;

    reg arvalid, arready;
    reg rvalid, rready;

    wire write_start;
    wire read_start;
    wire busy;

    axi_slave_fsm uut (
        .aclk(aclk),
        .aresetn(aresetn),

        .awvalid(awvalid),
        .awready(awready),
        .wvalid(wvalid),
        .wready(wready),
        .bvalid(bvalid),
        .bready(bready),

        .arvalid(arvalid),
        .arready(arready),
        .rvalid(rvalid),
        .rready(rready),

        .write_start(write_start),
        .read_start(read_start),
        .busy(busy)
    );

    always #5 aclk = ~aclk;

    initial begin
        aclk = 0;
        aresetn = 0;

        awvalid = 0;
        awready = 0;
        wvalid = 0;
        wready = 0;
        bvalid = 0;
        bready = 0;

        arvalid = 0;
        arready = 0;
        rvalid = 0;
        rready = 0;

        repeat(2) @(negedge aclk);
        aresetn = 1;

        // Write transaction
        @(negedge aclk);
        awvalid = 1;
        awready = 1;

        @(negedge aclk);
        awvalid = 0;
        awready = 0;
        wvalid = 1;
        wready = 1;

        @(negedge aclk);
        wvalid = 0;
        wready = 0;
        bvalid = 1;
        bready = 1;

        @(negedge aclk);
        bvalid = 0;
        bready = 0;

        // Read transaction
        @(negedge aclk);
        arvalid = 1;
        arready = 1;

        @(negedge aclk);
        arvalid = 0;
        arready = 0;
        rvalid = 1;
        rready = 1;

        @(negedge aclk);
        rvalid = 0;
        rready = 0;

        repeat(2) @(negedge aclk);

        $display("AXI SLAVE FSM TEST COMPLETED");
        $finish;
    end

endmodule