// Automatically generated by PRGA's RTL generator
`include "pktchain.vh"
module pktchain_frame_disassemble #(
    parameter DEPTH_LOG2 = 1,   // depth in terms of frames
    parameter DATA_WIDTH_LOG2 = `PRGA_PKTCHAIN_FRAME_SIZE_LOG2
) (
    input wire [0:0] prog_clk,
    input wire [0:0] prog_rst,

    output wire [0:0] frame_full,
    input wire [0:0] frame_wr,
    input wire [(1 << DATA_WIDTH_LOG2) - 1:0] frame_i,

    output wire [0:0] phit_wr,
    input wire [0:0] phit_full,
    output wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] phit_o
    );

    wire resizer_rd, resizer_empty, fifo_full, fifo_empty, fifo_rd;
    wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] resizer_dout, fifo_dout;

    assign frame_full = ~resizer_rd;

    prga_fifo_resizer #(
        .DATA_WIDTH                 (`PRGA_PKTCHAIN_PHIT_WIDTH)
        ,.INPUT_MULTIPLIER          (1 << (DATA_WIDTH_LOG2 - `PRGA_PKTCHAIN_PHIT_WIDTH_LOG2))
        ,.INPUT_LOOKAHEAD           (1)
        ,.OUTPUT_LOOKAHEAD          (1)
    ) resizer (
        .clk                        (prog_clk)
        ,.rst                       (prog_rst)
        ,.empty_i                   (~frame_wr)
        ,.rd_i                      (resizer_rd)
        ,.dout_i                    (frame_i)
        ,.empty                     (resizer_empty)
        ,.rd                        (~fifo_full)
        ,.dout                      (resizer_dout)
        );

    prga_fifo #(
        .DATA_WIDTH                 (`PRGA_PKTCHAIN_PHIT_WIDTH)
        ,.LOOKAHEAD                 (0)
        ,.DEPTH_LOG2                (DEPTH_LOG2)
    ) fifo (
        .clk                        (prog_clk)
        ,.rst                       (prog_rst)
        ,.full                      (fifo_full)
        ,.wr                        (~resizer_empty)
        ,.din                       (resizer_dout)
        ,.empty                     (fifo_empty)
        ,.rd                        (fifo_rd)
        ,.dout                      (fifo_dout)
        );

    prga_fifo_adapter #(
        .DATA_WIDTH                 (`PRGA_PKTCHAIN_PHIT_WIDTH)
        ,.INPUT_LOOKAHEAD           (0)
    ) adapter (
        .clk                        (prog_clk)
        ,.rst                       (prog_rst)
        ,.empty_i                   (fifo_empty)
        ,.rd_i                      (fifo_rd)
        ,.dout_i                    (fifo_dout)
        ,.wr_o                      (phit_wr)
        ,.full_o                    (phit_full)
        ,.din_o                     (phit_o)                  
        );

endmodule
