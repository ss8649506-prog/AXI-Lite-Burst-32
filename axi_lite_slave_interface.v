`timescale 1ns/1ps

module axi_lite_slave_interface #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter STRB_WIDTH     = DATA_WIDTH / 8,
    parameter REG_ADDR_WIDTH = 4,
    parameter BASE_ADDR      = 32'h40000000
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    // Write address channel
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,

    // Write data channel
    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]     s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output wire                      s_axi_wready,

    // Write response channel
    output wire [1:0]                s_axi_bresp,
    output wire                      s_axi_bvalid,
    input  wire                      s_axi_bready,

    // Read address channel
    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,

    // Read data channel
    output wire [DATA_WIDTH-1:0]     s_axi_rdata,
    output wire [1:0]                s_axi_rresp,
    output wire                      s_axi_rvalid,
    input  wire                      s_axi_rready,

    // Register interface
    output wire                      reg_wr_en,
    output wire [REG_ADDR_WIDTH-1:0] reg_wr_addr,
    output wire [DATA_WIDTH-1:0]     reg_wr_data,
    output wire [STRB_WIDTH-1:0]     reg_wr_strb,

    output wire                      reg_rd_en,
    output wire [REG_ADDR_WIDTH-1:0] reg_rd_addr,
    input  wire [DATA_WIDTH-1:0]     reg_rd_data
);

    // Address decoder signals
    wire [REG_ADDR_WIDTH-1:0] wr_reg_addr;
    wire                      wr_addr_valid;

    wire [REG_ADDR_WIDTH-1:0] rd_reg_addr;
    wire                      rd_addr_valid;

    // Write path signals
    wire wr_done;
    wire wr_error;

    // Read path signals
    wire rd_error;
    wire rd_pulse;

    // -------------------------------------------------------------
    // Address Decoders for Write and Read Channels
    // -------------------------------------------------------------
    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .BASE_ADDR(BASE_ADDR)
    ) wr_decoder (
        .addr(s_axi_awaddr),
        .reg_addr(wr_reg_addr),
        .addr_valid(wr_addr_valid)
    );

    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .BASE_ADDR(BASE_ADDR)
    ) rd_decoder (
        .addr(s_axi_araddr),
        .reg_addr(rd_reg_addr),
        .addr_valid(rd_addr_valid)
    );

    // -------------------------------------------------------------
    // Write Data Path
    // -------------------------------------------------------------
    write_data_path #(
        .ADDR_WIDTH(REG_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) write_path (
        .aclk(aclk),
        .aresetn(aresetn),

        .aw_reg_addr(wr_reg_addr),
        .aw_addr_valid(wr_addr_valid),
        .awvalid(s_axi_awvalid),
        .awready(s_axi_awready),

        .wdata(s_axi_wdata),
        .wstrb(s_axi_wstrb),
        .wvalid(s_axi_wvalid),
        .wready(s_axi_wready),

        .wr_en(reg_wr_en),
        .wr_addr(reg_wr_addr),
        .wr_data(reg_wr_data),
        .wr_strb(reg_wr_strb),

        .wr_done(wr_done),
        .wr_error(wr_error)
    );

    // -------------------------------------------------------------
    // Read Data Path
    // -------------------------------------------------------------
    read_data_path #(
        .ADDR_WIDTH(REG_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) read_path (
        .aclk(aclk),
        .aresetn(aresetn),

        .ar_reg_addr(rd_reg_addr),
        .ar_addr_valid(rd_addr_valid),
        .arvalid(s_axi_arvalid),
        .arready(s_axi_arready),

        .reg_rd_data(reg_rd_data),
        .rd_addr(reg_rd_addr),
        .rd_en(reg_rd_en),

        .rdata(s_axi_rdata),
        .rvalid(s_axi_rvalid),
        .rready(s_axi_rready),

        .rd_error(rd_error)
    );

    // -------------------------------------------------------------
    // Response Generation
    // -------------------------------------------------------------
    wire bvalid_int;
    wire [1:0] bresp_int;
    wire rvalid_unused;
    wire [1:0] rresp_int;

    response_logic response_unit (
        .aclk(aclk),
        .aresetn(aresetn),

        .wr_done(wr_done),
        .wr_error(wr_error),
        .bvalid(bvalid_int),
        .bready(s_axi_bready),
        .bresp(bresp_int),

        .rd_done(reg_rd_en),
        .rd_error(rd_error),
        .rvalid(rvalid_unused),
        .rready(s_axi_rready),
        .rresp(rresp_int)
    );

    assign s_axi_bvalid = bvalid_int;
    assign s_axi_bresp  = bresp_int;

    // RRESP is valid synchronously with RVALID
    assign s_axi_rresp  = rd_error ? 2'b10 : 2'b00;

endmodule
