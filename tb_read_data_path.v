`timescale 1ns/1ps

module tb_read_data_path;

    reg aclk;
    reg aresetn;

    reg [3:0] ar_reg_addr;
    reg ar_addr_valid;
    reg arvalid;
    wire arready;

    reg [31:0] reg_rd_data;

    wire [3:0] rd_addr;
    wire [31:0] rdata;
    wire rvalid;
    reg rready;

    wire rd_en;
    wire rd_error;

    integer checks;

    read_data_path uut (
        .aclk(aclk),
        .aresetn(aresetn),
        .ar_reg_addr(ar_reg_addr),
        .ar_addr_valid(ar_addr_valid),
        .arvalid(arvalid),
        .arready(arready),
        .reg_rd_data(reg_rd_data),
        .rd_addr(rd_addr),
        .rdata(rdata),
        .rvalid(rvalid),
        .rready(rready),
        .rd_en(rd_en),
        .rd_error(rd_error)
    );

    always #5 aclk = ~aclk;

    initial begin
        aclk = 0;
        aresetn = 0;
        ar_reg_addr = 0;
        ar_addr_valid = 0;
        arvalid = 0;
        reg_rd_data = 0;
        rready = 0;
        checks = 0;

        repeat (2) @(negedge aclk);
        aresetn = 1;

        // TEST 1
        @(negedge aclk);
        ar_reg_addr = 4'h1;
        ar_addr_valid = 1;
        reg_rd_data = 32'hAABBCCDD;
        arvalid = 1;

        @(negedge aclk);
        arvalid = 0;

        wait (rvalid == 1);
        #1;

        if (rdata !== 32'hAABBCCDD || rd_error !== 0)
            $fatal(1, "FAIL: Read test 1");
        else begin
            $display("PASS: Read test 1");
            checks = checks + 1;
        end

        @(negedge aclk);
        rready = 1;
        @(negedge aclk);
        rready = 0;

        // TEST 2
        @(negedge aclk);
        ar_reg_addr = 4'h3;
        ar_addr_valid = 1;
        reg_rd_data = 32'h11223344;
        arvalid = 1;

        @(negedge aclk);
        arvalid = 0;

        wait (rvalid == 1);
        #1;

        if (rdata !== 32'h11223344 || rd_error !== 0)
            $fatal(1, "FAIL: Read test 2");
        else begin
            $display("PASS: Read test 2");
            checks = checks + 1;
        end

        @(negedge aclk);
        rready = 1;
        @(negedge aclk);
        rready = 0;

        // TEST 3: Invalid address
        @(negedge aclk);
        ar_reg_addr = 4'h0;
        ar_addr_valid = 0;
        arvalid = 1;

        @(negedge aclk);
        arvalid = 0;

        wait (rvalid == 1);
        #1;

        if (rdata !== 32'h00000000 || rd_error !== 1)
            $fatal(1, "FAIL: Invalid address test");
        else begin
            $display("PASS: Invalid address test");
            checks = checks + 1;
        end

        $display("ALL READ DATA PATH TESTS PASSED");
        $display("Total checks = %0d", checks);

        $finish;
    end

endmodule