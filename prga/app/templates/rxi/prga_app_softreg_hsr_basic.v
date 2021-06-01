// Automatically generated by PRGA's RTL generator
module prga_app_softreg_hsr_basic #(
    parameter   DATA_WIDTH  = 32
    , parameter RSTVAL = 32'b0
) (
    input wire                          clk
    , input wire                        rst_n

    // -- system-side --------------------------------------------------------
    // -- request --
    , output wire                       req_rdy
    , input wire                        req_vld
    , input wire                        req_we
    , input wire [DATA_WIDTH - 1:0]     req_wmask
    , input wire [DATA_WIDTH - 1:0]     req_data

    // -- response --
    , input wire                        resp_rdy
    , output wire                       resp_vld
    , output wire [DATA_WIDTH - 1:0]    resp_data

    // -- kernel-side --------------------------------------------------------
    , output reg [DATA_WIDTH - 1:0]     var_o
    );

    always @(posedge clk) begin
        if (~rst_n) begin
            var_o <= RSTVAL;
        end else if (req_rdy && req_vld && req_we) begin
            var_o <= (req_wmask & req_data) | (~req_wmask & var_o);
        end
    end

    assign req_rdy = 1'b1;  // always ready
    assign resp_vld = 1'b1; // always valid
    assign resp_data = var_o;

endmodule
