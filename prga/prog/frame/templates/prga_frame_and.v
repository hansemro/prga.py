// Automatically generated by PRGA's RTL generator
`timescale 1ns/1ps
module {{ module.name }} (
    input wire ix
    , input wire iy
    , output wire o
    );

    assign o = ix & iy;

endmodule