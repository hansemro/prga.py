// Automatically generated by PRGA's RTL generator
`timescale 1ns/1ps
`include "prga_utils.vh"
module {{ module.name }} #(
    parameter   ADDR_WIDTH = 12
    , parameter DATA_WIDTH = 8
    , parameter PROG_ADDR_WIDTH = 12
    , parameter PROG_DATA_WIDTH = 8
) (
    // user interface
    input wire                              u_clk
    , input wire                            u_we
    , input wire [ADDR_WIDTH - 1:0]         u_waddr
    , input wire [DATA_WIDTH - 1:0]         u_din
    , input wire [DATA_WIDTH - 1:0]         u_bw
    , input wire                            u_re
    , input wire [ADDR_WIDTH - 1:0]         u_raddr
    , output wire [DATA_WIDTH - 1:0]        u_dout

    // programmming interface
    , input wire                            prog_clk
    , input wire                            prog_rst
    , input wire                            prog_done
    , input wire [PROG_ADDR_WIDTH - 1:0]    prog_addr
    , input wire [PROG_DATA_WIDTH - 1:0]    prog_din
    , input wire                            prog_ce
    , input wire                            prog_we
    , output reg [PROG_DATA_WIDTH - 1:0]    prog_dout

    // SRAM IP interface
    , output wire                           ip_clk
    , output wire                           ip_rst
    , output wire                           ip_we
    , output wire [ADDR_WIDTH - 1:0]        ip_waddr
    , output wire [DATA_WIDTH - 1:0]        ip_din
    , output wire [DATA_WIDTH - 1:0]        ip_bw
    , output wire                           ip_re
    , output wire [ADDR_WIDTH - 1:0]        ip_raddr
    , input wire [DATA_WIDTH - 1:0]         ip_dout
    );

    localparam  NUM_SLICES = DATA_WIDTH / PROG_DATA_WIDTH + (DATA_WIDTH % PROG_DATA_WIDTH > 0 ? 1 : 0);
    localparam  OFFSET_WIDTH = NUM_SLICES == 1 ? 0 : `PRGA_CLOG2(NUM_SLICES);

    // programming data
    wire [NUM_SLICES * PROG_DATA_WIDTH - 1:0] prog_din_aligned;
    assign prog_din_aligned = { NUM_SLICES {prog_din} };

    wire [NUM_SLICES * PROG_DATA_WIDTH - 1:0] prog_bw;

    genvar gv_prog_bw, gv_prog_dout_candidates;
    generate if (OFFSET_WIDTH == 0) begin
        assign prog_bw = { PROG_DATA_WIDTH {1'b1} };

        always @* begin
            prog_dout = { PROG_DATA_WIDTH {1'b0} };
            prog_dout[0 +: DATA_WIDTH] = ip_dout;
        end

    end else begin
        for (gv_prog_bw = 0; gv_prog_bw < NUM_SLICES; gv_prog_bw = gv_prog_bw + 1) begin
            assign prog_bw[gv_prog_bw * PROG_DATA_WIDTH +: PROG_DATA_WIDTH] = { PROG_DATA_WIDTH {prog_addr[0 +: OFFSET_WIDTH] == gv_prog_bw} };
        end

        reg [OFFSET_WIDTH - 1:0] offset_f;
        always @(posedge prog_clk) begin
            if (prog_rst) begin
                offset_f <= { OFFSET_WIDTH {1'b0} };
            end else begin
                offset_f <= (prog_ce & !prog_we) ? prog_addr[0 +: OFFSET_WIDTH] : { OFFSET_WIDTH {1'b0} };
            end
        end

        wire [PROG_DATA_WIDTH - 1:0] prog_dout_candidates [0:NUM_SLICES - 1];
        for (gv_prog_dout_candidates = 0; gv_prog_dout_candidates < NUM_SLICES; gv_prog_dout_candidates = gv_prog_dout_candidates + 1) begin
            assign prog_dout_candidates[gv_prog_dout_candidates] = ip_dout[gv_prog_dout_candidates * PROG_DATA_WIDTH +: PROG_DATA_WIDTH];
        end

        always @* begin
            prog_dout = prog_dout_candidates[offset_f];
        end

    end endgenerate

    // XXX: the muxes below must be taken care of in a real tape-out because
    // they are in different clock domains!

    assign ip_clk   = prog_done ? u_clk : prog_clk;  // XXX: especially this one!!!
    assign ip_rst   = prog_rst;
    assign ip_we    = prog_done ? u_we : (prog_ce & prog_we);
    assign ip_waddr = prog_done ? u_waddr : prog_addr[PROG_ADDR_WIDTH - 1:OFFSET_WIDTH];
    assign ip_din   = prog_done ? u_din : prog_din_aligned[0 +: DATA_WIDTH];
    assign ip_bw    = prog_done ? u_bw : prog_bw[0 +: DATA_WIDTH];
    assign ip_re    = prog_done ? u_re : prog_ce;
    assign ip_raddr = prog_done ? u_raddr : prog_addr[PROG_ADDR_WIDTH - 1:OFFSET_WIDTH];
    assign u_dout   = ip_dout;

endmodule
