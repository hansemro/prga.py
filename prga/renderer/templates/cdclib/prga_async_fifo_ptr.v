// Automatically generated by PRGA's RTL generator
module prga_async_fifo_ptr #(
    parameter   DEPTH_LOG2 = 1
    , parameter ASYNC_RST = 0
) (
    // synchronous in `wclk` domain if ~ASYNC_RST
    // Assumption:  once `rst_n` is asserted, it must be held until
    //              `rst_n_echo_wclk` is asserted
    input wire                      rst_n
    , output wire                   rst_n_rclk

    , input wire                    wclk
    , input wire                    wr
    , output wire                   full
    , output wire [DEPTH_LOG2:0]    wptr

    , input wire                    rclk
    , input wire                    rd
    , output wire                   empty
    , output wire [DEPTH_LOG2:0]    rptr
    );

    // == Synchronize rst_n in wclk domain ==
    reg rst_n_wclk;

    generate if (ASYNC_RST) begin
        always @(posedge wclk or negedge rst_n) begin
            if (~rst_n) begin
                rst_n_wclk <= 1'b0;
            end else begin
                rst_n_wclk <= 1'b1;
            end
        end
    end else begin
        always @(posedge wclk) begin
            rst_n_wclk <= rst_n;
        end
    end endgenerate

    // == Synchronize rst_n over to the rclk domain & collect echo ==
    wire rst_n_echo_wclk;

    prga_sync_basic #(
        .DATA_WIDTH     (1)
    ) i_sync_wclk2rclk_rst_n (
        .idata  (rst_n_wclk)
        ,.oclk  (rclk)
        ,.odata (rst_n_rclk)
        );

    prga_sync_basic #(
        .DATA_WIDTH     (1)
    ) i_sync_rclk2wclk_rst_n (
        .idata  (rst_n_rclk)
        ,.oclk  (wclk)
        ,.odata (rst_n_echo_wclk)
        );

    // == Counters ==
    reg [DEPTH_LOG2:0]  b_wptr_wclk, b_wptr_rclk, b_rptr_wclk, b_rptr_rclk;
    wire [DEPTH_LOG2:0] g_wptr_wclk, g_wptr_rclk, g_rptr_wclk, g_rptr_rclk, b_wptr_rclk_next, b_rptr_wclk_next;

    // binary-to-gray converting logic
    assign g_wptr_wclk = b_wptr_wclk ^ (b_wptr_wclk >> 1);
    assign g_rptr_rclk = b_rptr_rclk ^ (b_rptr_rclk >> 1);

    // sync `wptr` from `wclk` domain to `rclk` domain
    prga_sync_basic #(
        .DATA_WIDTH     (DEPTH_LOG2 + 1)
    ) i_sync_wclk2rclk_wptr (
        .idata  (g_wptr_wclk)
        ,.oclk  (rclk)
        ,.odata (g_wptr_rclk)
        );

    // sync `rptr` from `rclk` domain to `wclk` domain
    prga_sync_basic #(
        .DATA_WIDTH     (DEPTH_LOG2 + 1)
    ) i_sync_rclk2wclk_rptr (
        .idata  (g_rptr_rclk)
        ,.oclk  (wclk)
        ,.odata (g_rptr_wclk)
        );

    // gray-to-binary converting logic
    genvar i;
    generate
        for (i = 0; i < DEPTH_LOG2 + 1; i = i + 1) begin: b2g
            assign b_wptr_rclk_next[i] = ^(g_wptr_rclk >> i);
            assign b_rptr_wclk_next[i] = ^(g_rptr_wclk >> i);
        end
    endgenerate

    // `wclk` domain flops
    always @(posedge wclk) begin
        if (~rst_n_wclk || ~rst_n_echo_wclk) begin
            b_wptr_wclk <= { (DEPTH_LOG2 + 1) {1'b0} };
            b_rptr_wclk <= { (DEPTH_LOG2 + 1) {1'b0} };
        end else begin
            if (wr && !full)
                b_wptr_wclk <= b_wptr_wclk + 1;
            b_rptr_wclk <= b_rptr_wclk_next; 
        end
    end

    // `rclk` domain flops
    always @(posedge rclk) begin
        if (~rst_n_rclk) begin
            b_rptr_rclk <= { (DEPTH_LOG2 + 1) {1'b0} };
            b_wptr_rclk <= { (DEPTH_LOG2 + 1) {1'b0} };
        end else begin
            if (rd && !empty)
                b_rptr_rclk <= b_rptr_rclk + 1;
            b_wptr_rclk <= b_wptr_rclk_next;
            b_rptr_wclk <= b_rptr_wclk_next; 
        end
    end

    // full/empty signals 
    assign full = ~rst_n_wclk || ~rst_n_echo_wclk
                  || b_rptr_wclk == {~b_wptr_wclk[DEPTH_LOG2], b_wptr_wclk[0+:DEPTH_LOG2]};
    assign empty = ~rst_n_rclk || b_rptr_rclk == b_wptr_rclk;

    // pointer output
    assign wptr = b_wptr_wclk;
    assign rptr = b_rptr_rclk;

endmodule
