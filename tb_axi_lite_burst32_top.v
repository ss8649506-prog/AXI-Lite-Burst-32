`timescale 1ns/1ps

module tb_axi_lite_burst32_top;

    reg aclk;
    reg aresetn;

    reg [31:0] s_axi_awaddr;
    reg s_axi_awvalid;
    wire s_axi_awready;

    reg [31:0] s_axi_wdata;
    reg [3:0] s_axi_wstrb;
    reg s_axi_wvalid;
    wire s_axi_wready;

    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    reg s_axi_bready;

    reg [31:0] s_axi_araddr;
    reg s_axi_arvalid;
    wire s_axi_arready;

    wire [31:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    reg s_axi_rready;

    reg burst_start;
    reg [31:0] burst_start_addr;
    reg [7:0] burst_length;
    wire burst_active;
    wire burst_done;

    wire low_power_enable;

    integer checks;

    axi_lite_burst32_top uut (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .burst_start(burst_start),
        .burst_start_addr(burst_start_addr),
        .burst_length(burst_length),
        .burst_active(burst_active),
        .burst_done(burst_done),

        .low_power_enable(low_power_enable)
    );

    always #5 aclk = ~aclk;

    initial begin
        aclk = 0;
        aresetn = 0;

        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;

        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        burst_start = 0;
        burst_start_addr = 32'h40000000;
        burst_length = 4;

        checks = 0;

        repeat(2) @(negedge aclk);
        aresetn = 1;

        // -------------------------
        // WRITE TRANSACTION
        // -------------------------
        @(negedge aclk);
        s_axi_awaddr = 32'h40000004;
        s_axi_awvalid = 1;

        s_axi_wdata = 32'hAABBCCDD;
        s_axi_wstrb = 4'hF;
        s_axi_wvalid = 1;

        wait(s_axi_awready && s_axi_wready);

        @(negedge aclk);
        s_axi_awvalid = 0;
        s_axi_wvalid = 0;

        wait(s_axi_bvalid);
        #1;

        if (s_axi_bresp !== 2'b00)
            $fatal(1, "FAIL: Write response");
        else begin
            $display("PASS: Write response");
            checks = checks + 1;
        end

        @(negedge aclk);
        s_axi_bready = 1;

        @(negedge aclk);
        s_axi_bready = 0;

        // -------------------------
        // READ TRANSACTION
        // -------------------------
        @(negedge aclk);
        s_axi_araddr = 32'h40000004;
        s_axi_arvalid = 1;

        @(negedge aclk);
        s_axi_arvalid = 0;

        wait(s_axi_rvalid);
        #1;

        if (s_axi_rdata !== 32'hAABBCCDD)
            $fatal(1, "FAIL: Read data = %h", s_axi_rdata);
        else begin
            $display("PASS: Read data = %h", s_axi_rdata);
            checks = checks + 1;
        end

        @(negedge aclk);
        s_axi_rready = 1;

        @(negedge aclk);
        s_axi_rready = 0;

        // -------------------------
        // BURST CONTROLLER
        // -------------------------
        @(negedge aclk);
        burst_start = 1;

        @(negedge aclk);
        burst_start = 0;

        wait(burst_done);
        #1;

        $display("PASS: Burst controller completed");
        checks = checks + 1;

        $display("TOP LEVEL TEST COMPLETED");
        $display("Total checks = %0d", checks);

        $finish;
    end

endmodule