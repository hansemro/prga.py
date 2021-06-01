// Automatically generated by PRGA's RTL generator
module prga_bitreverse #(
    parameter   DATA_WIDTH = 8
) (
    input wire [DATA_WIDTH-1:0]     data_i,
    output wire [DATA_WIDTH-1:0]    data_o
    );

    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin: g_rev
            assign data_o[DATA_WIDTH - 1 - i] = data_i[i];
        end
    endgenerate

endmodule