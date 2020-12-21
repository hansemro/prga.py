// Automatically generated by PRGA's RTL generator
`timescale 1ns/1ps
module prga_ram_1r1w #(
    parameter   DATA_WIDTH = 32
    , parameter ADDR_WIDTH = 10
) (
    input wire clk
    , input wire rst

    , input wire re
    , input wire [ADDR_WIDTH - 1:0] raddr
    , output reg [DATA_WIDTH - 1:0] dout

    , input wire we
    , input wire [ADDR_WIDTH - 1:0] waddr
    , input wire [DATA_WIDTH - 1:0] din
    , input wire [DATA_WIDTH - 1:0] bw
    );

    localparam  DATA_ROWS = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH - 1:0] data [0:DATA_ROWS - 1];

    integer i, j;
    initial
        for (j = 0; j < DATA_WIDTH; j = j + 1) begin
            dout[j] = $unsigned($random) % 2;

            for (i = 0; i < DATA_ROWS; i = i + 1)
                data[i][j] = $unsigned($random) % 2;
        end

    always @(posedge clk) begin
        if (rst) begin
            dout    <= {DATA_WIDTH {1'b0} };
        end else begin
            if (we) begin
                data[waddr] <= (bw & din) | (~bw & data[waddr]);
            end

            if (re) begin
                dout <= data[raddr];
            end
        end
    end

endmodule
