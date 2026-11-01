
`timescale 1ns/1ps

module tb_address_decoder;

    reg [31:0] addr;

    wire [3:0] reg_addr;
    wire addr_valid;

    integer checks;

    address_decoder uut (
        .addr(addr),
        .reg_addr(reg_addr),
        .addr_valid(addr_valid)
    );

    task check_address;
        input [31:0] test_addr;
        input [3:0] expected_reg;
        input expected_valid;

        begin
            addr = test_addr;
            #10;

            checks = checks + 1;

            if ((reg_addr === expected_reg) &&
                (addr_valid === expected_valid)) begin

                $display("PASS: Addr=%h Reg=%h Valid=%b",
                         addr, reg_addr, addr_valid);
            end
            else begin
                $display("FAIL: Addr=%h Expected Reg=%h Valid=%b Got Reg=%h Valid=%b",
                         addr, expected_reg, expected_valid,
                         reg_addr, addr_valid);

                $fatal(1, "Address decoder test failed");
            end
        end
    endtask

    initial begin

        checks = 0;
        addr = 0;

        check_address(32'h40000000, 4'h0, 1'b1);
        check_address(32'h40000004, 4'h1, 1'b1);
        check_address(32'h40000008, 4'h2, 1'b1);
        check_address(32'h4000000C, 4'h3, 1'b1);
        check_address(32'h40000010, 4'h4, 1'b1);
        check_address(32'h4000003C, 4'hF, 1'b1);

        // Invalid address
        check_address(32'h40000040, 4'h0, 1'b0);

        // Unaligned address
        check_address(32'h40000002, 4'h0, 1'b0);

        // Different address region
        check_address(32'h50000000, 4'h0, 1'b0);

        $display("--------------------------------");
        $display("ALL ADDRESS DECODER TESTS PASSED");
        $display("Total checks = %0d", checks);
        $display("--------------------------------");

        $finish;
    end

endmodule
