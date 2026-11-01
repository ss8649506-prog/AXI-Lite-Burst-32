
`timescale 1ns/1ps

module tb_reg_mem_bank;

    reg aclk;
    reg aresetn;

    reg wr_en;
    reg [3:0] wr_addr;
    reg [31:0] wr_data;
    reg [3:0] wr_strb;

    reg [3:0] rd_addr;
    wire [31:0] rd_data;

    integer checks;

    reg_mem_bank uut (
        .aclk(aclk),
        .aresetn(aresetn),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_strb(wr_strb),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    always #5 aclk = ~aclk;

    task write_register;
        input [3:0] address;
        input [31:0] data;
        input [3:0] strobe;
        begin
            @(negedge aclk);
            wr_en = 1'b1;
            wr_addr = address;
            wr_data = data;
            wr_strb = strobe;

            @(negedge aclk);
            wr_en = 1'b0;
        end
    endtask

    task check_register;
        input [3:0] address;
        input [31:0] expected;
        begin
            rd_addr = address;
            #1;
            checks = checks + 1;

            if (rd_data === expected)
                $display("PASS: Address=%0d Data=%h",
                         address, rd_data);
            else begin
                $display("FAIL: Address=%0d Expected=%h Got=%h",
                         address, expected, rd_data);
                $fatal(1, "Register bank test failed");
            end
        end
    endtask

    initial begin
        aclk = 0;
        aresetn = 0;
        wr_en = 0;
        wr_addr = 0;
        wr_data = 0;
        wr_strb = 0;
        rd_addr = 0;
        checks = 0;

        #12;
        aresetn = 1;
        #2;

        // Reset check
        check_register(0, 32'h00000000);

        // Full write
        write_register(0, 32'hAABBCCDD, 4'b1111);
        check_register(0, 32'hAABBCCDD);

        // Partial write
        write_register(0, 32'h11223344, 4'b0101);
        check_register(0, 32'hAA22CC44);

        // Independent register
        write_register(3, 32'hDEADBEEF, 4'b1111);
        check_register(3, 32'hDEADBEEF);

        // Check original register
        check_register(0, 32'hAA22CC44);

        // Reset again
        aresetn = 0;
        #2;
        check_register(0, 32'h00000000);
        check_register(3, 32'h00000000);

        $display("--------------------------------");
        $display("ALL REGISTER BANK TESTS PASSED");
        $display("Total read checks = %0d", checks);
        $display("--------------------------------");

        $finish;
    end

endmodule

