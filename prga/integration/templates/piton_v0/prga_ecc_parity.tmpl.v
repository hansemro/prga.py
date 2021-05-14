// Automatically generated by PRGA's RTL generator

/*
* Parity checker.
*/

`include "prga_system.vh"

`ifdef DEFAULT_NETTYPE_NONE
`default_nettype none
`endif

module prga_ecc_parity #(
    parameter   DATA_WIDTH  = 32
) (
    input wire                                  clk,
    input wire                                  rst_n,

    input wire [DATA_WIDTH-1:0]                 data,
    input wire [`PRGA_ECC_WIDTH-1:0]            ecc,
    
    output reg                                  fail
    );

    always @* begin
        fail = ~^{data, ecc};
    end

endmodule
