module axi_slave_fsm (
    input wire aclk,
    input wire aresetn,

    input wire awvalid,
    input wire awready,
    input wire wvalid,
    input wire wready,
    input wire bvalid,
    input wire bready,

    input wire arvalid,
    input wire arready,
    input wire rvalid,
    input wire rready,

    output reg write_start,
    output reg read_start,
    output reg busy
);

    localparam IDLE       = 3'b000;
    localparam WRITE_ADDR = 3'b001;
    localparam WRITE_DATA = 3'b010;
    localparam WRITE_RESP = 3'b011;
    localparam READ_ADDR  = 3'b100;
    localparam READ_RESP  = 3'b101;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (awvalid)
                    next_state = WRITE_ADDR;
                else if (arvalid)
                    next_state = READ_ADDR;
            end

            WRITE_ADDR: begin
                if (awvalid && awready)
                    next_state = WRITE_DATA;
            end

            WRITE_DATA: begin
                if (wvalid && wready)
                    next_state = WRITE_RESP;
            end

            WRITE_RESP: begin
                if (bvalid && bready)
                    next_state = IDLE;
            end

            READ_ADDR: begin
                if (arvalid && arready)
                    next_state = READ_RESP;
            end

            READ_RESP: begin
                if (rvalid && rready)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    always @(*) begin
        write_start = 1'b0;
        read_start  = 1'b0;
        busy        = 1'b1;

        case (state)
            IDLE: begin
                busy = 1'b0;
            end

            WRITE_ADDR: begin
                write_start = 1'b1;
            end

            WRITE_DATA: begin
                write_start = 1'b1;
            end

            READ_ADDR: begin
                read_start = 1'b1;
            end

            READ_RESP: begin
                read_start = 1'b1;
            end

            default: begin
                write_start = 1'b0;
                read_start  = 1'b0;
            end
        endcase
    end

endmodule