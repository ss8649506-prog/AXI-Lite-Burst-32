`timescale 1ns/1ps

module tb_response_logic;

    reg aclk;
    reg aresetn;

    reg wr_done;
    reg wr_error;
    wire bvalid;
    reg bready;
    wire [1:0] bresp;

    reg rd_done;
    reg rd_error;
    wire rvalid;
    reg rready;
    wire [1:0] rresp;

    integer checks;

    response_logic uut (
        .aclk(aclk),
        .aresetn(aresetn),

        .wr_done(wr_done),
        .wr_error(wr_error),
        .bvalid(bvalid),
        .bready(bready),
        .bresp(bresp),

        .rd_done(rd_done),
        .rd_error(rd_error),
        .rvalid(rvalid),
        .rready(rready),
        .rresp(rresp)
    );

    always #5 aclk = ~aclk;

    initial begin
        aclk = 0;
        aresetn = 0;
        wr_done = 0;
        wr_error = 0;
        bready = 0;
        rd_done = 0;
        rd_error = 0;
        rready = 0;
        checks = 0;

        repeat(2) @(negedge aclk);
        aresetn = 1;

        // Successful write response
        @(negedge aclk);
        wr_done = 1;
        wr_error = 0;

        @(negedge aclk);
        wr_done = 0;
        #1;

        if (bvalid !== 1'b1 || bresp !== 2'b00)
            $fatal(1, "FAIL: Write OKAY response");
        else begin
            $display("PASS: Write OKAY response");
            checks = checks + 1;
        end

        @(negedge aclk);
        bready = 1;

        @(negedge aclk);
        bready = 0;

        // Error write response
        @(negedge aclk);
        wr_done = 1;
        wr_error = 1;

        @(negedge aclk);
        wr_done = 0;
        #1;

        if (bvalid !== 1'b1 || bresp !== 2'b10)
            $fatal(1, "FAIL: Write SLVERR response");
        else begin
            $display("PASS: Write SLVERR response");
            checks = checks + 1;
        end

        @(negedge aclk);
        bready = 1;

        @(negedge aclk);
        bready = 0;

        // Successful read response
        @(negedge aclk);
        rd_done = 1;
        rd_error = 0;

        @(negedge aclk);
        rd_done = 0;
        #1;

        if (rvalid !== 1'b1 || rresp !== 2'b00)
            $fatal(1, "FAIL: Read OKAY response");
        else begin
            $display("PASS: Read OKAY response");
            checks = checks + 1;
        end

        @(negedge aclk);
        rready = 1;

        @(negedge aclk);
        rready = 0;

        // Error read response
        @(negedge aclk);
        rd_done = 1;
        rd_error = 1;

        @(negedge aclk);
        rd_done = 0;
        #1;

        if (rvalid !== 1'b1 || rresp !== 2'b10)
            $fatal(1, "FAIL: Read SLVERR response");
        else begin
            $display("PASS: Read SLVERR response");
            checks = checks + 1;
        end

        $display("ALL RESPONSE LOGIC TESTS PASSED");
        $display("Total checks = %0d", checks);
        $finish;
    end

endmodule