
`timescale 1ns/1ps

module tb_write_data_path;

    reg aclk;
    reg aresetn;

    reg [3:0] aw_reg_addr;
    reg aw_addr_valid;

    reg awvalid;
    wire awready;

    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg wvalid;
    wire wready;

    wire wr_en;
    wire [3:0] wr_addr;
    wire [31:0] wr_data;
    wire [3:0] wr_strb;

    wire wr_done;
    wire wr_error;

    integer checks;

    write_data_path uut (
        .aclk(aclk),
        .aresetn(aresetn),

        .aw_reg_addr(aw_reg_addr),
        .aw_addr_valid(aw_addr_valid),

        .awvalid(awvalid),
        .awready(awready),

        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_strb(wr_strb),

        .wr_done(wr_done),
        .wr_error(wr_error)
    );

    always #5 aclk = ~aclk;

    task send_aw;
        input [3:0] address;
        input valid_address;
        begin
            @(negedge aclk);
            aw_reg_addr = address;
            aw_addr_valid = valid_address;
            awvalid = 1'b1;

            @(posedge aclk);
            while (!awready)
                @(posedge aclk);

            @(negedge aclk);
            awvalid = 1'b0;
        end
    endtask

    task send_w;
        input [31:0] data;
        input [3:0] strobe;
        begin
            @(negedge aclk);
            wdata = data;
            wstrb = strobe;
            wvalid = 1'b1;

            @(posedge aclk);
            while (!wready)
                @(posedge aclk);

            @(negedge aclk);
            wvalid = 1'b0;
        end
    endtask

    task check_write;
        input [3:0] expected_addr;
        input [31:0] expected_data;
        input [3:0] expected_strb;
        input expected_error;
        begin
            wait (wr_done == 1'b1);
            #1;

            checks = checks + 1;

            if (wr_addr === expected_addr &&
                wr_data === expected_data &&
                wr_strb === expected_strb &&
                wr_error === expected_error) begin

                $display("PASS: ADDR=%h DATA=%h STRB=%h ERROR=%b",
                    wr_addr, wr_data, wr_strb, wr_error);
            end
            else begin
                $display("FAIL: Write transaction mismatch");
                $fatal(1, "Write data path test failed");
            end

            @(posedge aclk);
            #1;
        end
    endtask

    initial begin
        aclk = 0;
        aresetn = 0;

        aw_reg_addr = 0;
        aw_addr_valid = 0;
        awvalid = 0;

        wdata = 0;
        wstrb = 0;
        wvalid = 0;

        checks = 0;

        #12;
        aresetn = 1;

        // Test 1: Address arrives before data
        fork
            send_aw(4'h1, 1'b1);
            begin
                #20;
                send_w(32'hAABBCCDD, 4'b1111);
            end
            check_write(4'h1, 32'hAABBCCDD,
                        4'b1111, 1'b0);
        join

        // Test 2: Data arrives before address
        fork
            send_w(32'h11223344, 4'b0101);
            begin
                #20;
                send_aw(4'h3, 1'b1);
            end
            check_write(4'h3, 32'h11223344,
                        4'b0101, 1'b0);
        join

        // Test 3: Invalid address
        fork
            send_aw(4'h0, 1'b0);
            send_w(32'hDEADBEEF, 4'b1111);
            check_write(4'h0, 32'hDEADBEEF,
                        4'b1111, 1'b1);
        join

        $display("--------------------------------");
        $display("ALL WRITE DATA PATH TESTS PASSED");
        $display("Total checks = %0d", checks);
        $display("--------------------------------");

        $finish;
    end

endmodule

