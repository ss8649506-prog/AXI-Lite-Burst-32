`timescale 1ns/1ps

module axi_lite_burst32_top #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter STRB_WIDTH     = DATA_WIDTH / 8,
    parameter REG_ADDR_WIDTH = 4,
    parameter REG_DEPTH      = 16,
    parameter BASE_ADDR      = 32'h40000000
)(
    input  wire                  aclk,
    input  wire                  aresetn,

    // AXI Write Address Channel
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output wire                  s_axi_awready,

    // AXI Write Data Channel
    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [STRB_WIDTH-1:0] s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output wire                  s_axi_wready,

    // AXI Write Response Channel
    output wire [1:0]            s_axi_bresp,
    output wire                  s_axi_bvalid,
    input  wire                  s_axi_bready,

    // AXI Read Address Channel
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output wire                  s_axi_arready,

    // AXI Read Data Channel
    output wire [DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0]            s_axi_rresp,
    output wire                  s_axi_rvalid,
    input  wire                  s_axi_rready,

    // Burst Control Interface
    input  wire                  burst_start,
    input  wire [ADDR_WIDTH-1:0] burst_start_addr,
    input  wire [7:0]            burst_length,
    output wire                  burst_active,
    output wire                  burst_done,

    // Low-Power Management
    output wire                  low_power_enable
);

    // Internal interconnect between slave interface and register bank
    wire                      reg_wr_en;
    wire [REG_ADDR_WIDTH-1:0] reg_wr_addr;
    wire [DATA_WIDTH-1:0]     reg_wr_data;
    wire [STRB_WIDTH-1:0]     reg_wr_strb;

    wire                      reg_rd_en;
    wire [REG_ADDR_WIDTH-1:0] reg_rd_addr;
    wire [DATA_WIDTH-1:0]     reg_rd_data;

    wire [ADDR_WIDTH-1:0]     burst_current_addr;
    wire [7:0]                burst_beat_count;
    wire                      burst_axi_valid;

    wire                      busy;

    // -------------------------------------------------------------
    // 16 x 32-bit Register Memory Bank
    // -------------------------------------------------------------
    reg_mem_bank #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(REG_ADDR_WIDTH),
        .DEPTH(REG_DEPTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) register_bank (
        .aclk(aclk),
        .aresetn(aresetn),
        .wr_en(reg_wr_en),
        .wr_addr(reg_wr_addr),
        .wr_data(reg_wr_data),
        .wr_strb(reg_wr_strb),
        .rd_addr(reg_rd_addr),
        .rd_data(reg_rd_data)
    );

    // -------------------------------------------------------------
    // AXI4-Lite Slave Interface
    // -------------------------------------------------------------
    axi_lite_slave_interface #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .BASE_ADDR(BASE_ADDR)
    ) slave_interface (
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

        .reg_wr_en(reg_wr_en),
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data),
        .reg_wr_strb(reg_wr_strb),

        .reg_rd_en(reg_rd_en),
        .reg_rd_addr(reg_rd_addr),
        .reg_rd_data(reg_rd_data)
    );

    // -------------------------------------------------------------
    // Burst Controller Subsystem
    // -------------------------------------------------------------
    burst_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LEN_WIDTH(8)
    ) burst_unit (
        .aclk(aclk),
        .aresetn(aresetn),
        .start(burst_start),
        .write_mode(1'b1),
        .start_addr(burst_start_addr),
        .burst_len(burst_length),
        .current_addr(burst_current_addr),
        .beat_count(burst_beat_count),
        .burst_active(burst_active),
        .burst_done(burst_done),
        .axi_valid(burst_axi_valid),
        .axi_ready(s_axi_awready)
    );

    // -------------------------------------------------------------
    // Low-Power Management Unit
    // -------------------------------------------------------------
    low_power_controller #(
        .IDLE_COUNT_WIDTH(8),
        .IDLE_THRESHOLD(8'd10)
    ) low_power_unit (
        .aclk(aclk),
        .aresetn(aresetn),
        .busy(busy),
        .low_power_enable(low_power_enable)
    );

    // Activity detector
    assign busy = s_axi_awvalid |
                  s_axi_wvalid  |
                  s_axi_bvalid  |
                  s_axi_arvalid |
                  s_axi_rvalid  |
                  burst_active;

endmodule
