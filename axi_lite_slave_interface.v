module axi_lite_slave_interface #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH / 8
)(
    input wire aclk,
    input wire aresetn,

    // Write address channel
    input wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output wire s_axi_awready,

    // Write data channel
    input wire [DATA_WIDTH-1:0] s_axi_wdata,
    input wire [STRB_WIDTH-1:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output wire s_axi_wready,

    // Write response channel
    output wire [1:0] s_axi_bresp,
    output wire s_axi_bvalid,
    input wire s_axi_bready,

    // Read address channel
    input wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output wire s_axi_arready,

    // Read data channel
    output wire [DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rvalid,
    input wire s_axi_rready,

    // Register interface
    output wire reg_wr_en,
    output wire [ADDR_WIDTH-1:0] reg_wr_addr,
    output wire [DATA_WIDTH-1:0] reg_wr_data,
    output wire [STRB_WIDTH-1:0] reg_wr_strb,

    output wire reg_rd_en,
    output wire [ADDR_WIDTH-1:0] reg_rd_addr,
    input wire [DATA_WIDTH-1:0] reg_rd_data
);

    // Address decoder signals
    wire [3:0] wr_reg_addr;
    wire wr_addr_valid;

    wire [3:0] rd_reg_addr;
    wire rd_addr_valid;

    // Write path signals
    wire wr_done;
    wire wr_error;

    // Read path signals
    wire rd_done;
    wire rd_error;

    // Response logic internal signals
    wire bvalid_internal;
    wire rvalid_internal;
    wire [1:0] bresp_internal;
    wire [1:0] rresp_internal;

    // Address decoders
    address_decoder wr_decoder (
        .addr(s_axi_awaddr),
        .reg_addr(wr_reg_addr),
        .addr_valid(wr_addr_valid)
    );

    address_decoder rd_decoder (
        .addr(s_axi_araddr),
        .reg_addr(rd_reg_addr),
        .addr_valid(rd_addr_valid)
    );

    // Write data path
    write_data_path write_path (
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

    // Read data path
    read_data_path read_path (
        .aclk(aclk),
        .aresetn(aresetn),
        .ar_reg_addr(rd_reg_addr),
        .ar_addr_valid(rd_addr_valid),
        .arvalid(s_axi_arvalid),
        .arready(s_axi_arready),
        .reg_rd_data(reg_rd_data),
        .rd_addr(reg_rd_addr),
        .rdata(s_axi_rdata),
        .rvalid(s_axi_rvalid),
        .rready(s_axi_rready),
        .rd_en(reg_rd_en),
        .rd_error(rd_error)
    );

    // Response logic
    response_logic response_unit (
        .aclk(aclk),
        .aresetn(aresetn),

        .wr_done(wr_done),
        .wr_error(wr_error),
        .bvalid(bvalid_internal),
        .bready(s_axi_bready),
        .bresp(bresp_internal),

        .rd_done(rd_done),
        .rd_error(rd_error),
        .rvalid(rvalid_internal),
        .rready(s_axi_rready),
        .rresp(rresp_internal)
    );

    assign s_axi_bvalid = bvalid_internal;
    assign s_axi_bresp  = bresp_internal;

    assign s_axi_rresp  = rresp_internal;

    // Read completion pulse
    assign rd_done = s_axi_rvalid && s_axi_rready;

endmodule
