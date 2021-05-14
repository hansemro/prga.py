// Automatically generated by PRGA's RTL generator
module prga_simple_bufre (
    input wire [0:0] C,
    input wire [0:0] R,
    input wire [0:0] E,
    input wire [0:0] D,
    output reg [0:0] Q
    );

    always @(posedge C) begin
        if (R) begin
            Q <= 1'b0;
        end else if (E) begin
            Q <= D;
        end
    end

endmodule

