// Automatically generated by PRGA's RTL generator

/*
* Tag array for prga_yami_pitoncache.
*/

`include "prga_yami.vh"
`include "prga_yami_pitoncache.vh"
`default_nettype none

module prga_yami_pitoncache_tag_array #(
    parameter   INITIALIZE          = 1
    , parameter USE_INITIAL_BLOCK   = 0     // if set, use `initial` block to initialize the state array
                                            // this only works when the cache is implemented as a soft cache inside the FPGA
) (
    // -- System Ctrl --------------------------------------------------------
    input wire                                          clk
    , input wire                                        rst_n

    // -- Stage I ------------------------------------------------------------
    , output wire                                       busy_s1
    , input wire                                        rd_s1
    , input wire [`PRGA_YAMI_CACHE_INDEX_WIDTH-1:0]     index_s1

    // -- Stage II -----------------------------------------------------------
    , output wire [`PRGA_YAMI_CACHE_TAG_WIDTH * `PRGA_YAMI_CACHE_NUM_WAYS - 1:0] rdata_s2

    // -- Stage III ----------------------------------------------------------
    , input wire                                        stall_s3
    , input wire [`PRGA_YAMI_CACHE_INDEX_WIDTH-1:0]     index_s3
    , input wire [`PRGA_YAMI_CACHE_NUM_WAYS_LOG2-1:0]   way_s3
    , input wire                                        wr_s3
    , input wire [`PRGA_YAMI_CACHE_TAG_WIDTH-1:0]       wdata_s3
    );

    localparam  LINE_WIDTH  = `PRGA_YAMI_CACHE_TAG_WIDTH * `PRGA_YAMI_CACHE_NUM_WAYS;

    // -- Tag Array Memory --
    wire                                    we;
    wire [`PRGA_YAMI_CACHE_INDEX_WIDTH-1:0] waddr;
    wire [LINE_WIDTH-1:0]                   din;
    reg [LINE_WIDTH-1:0]                    rdata_s3;

    prga_yami_pitoncache_ram_raw #(
        .ADDR_WIDTH     (`PRGA_YAMI_CACHE_INDEX_WIDTH)
        ,.DATA_WIDTH    (LINE_WIDTH)
        ,.INITIALIZE    (USE_INITIAL_BLOCK)
    ) i_mem (
        .clk        (clk)
        ,.rst_n     (rst_n)
        ,.we        (we)
        ,.waddr     (waddr) // @(posedge clk) index_s3 <= index_s2; index_s2 <= index_s1;
        ,.d         (din)
        ,.re        (rd_s1)
        ,.raddr     (index_s1)
        ,.q         (rdata_s2)
        );

    always @(posedge clk) begin
        if (~rst_n) begin
            rdata_s3    <= { LINE_WIDTH {1'b0} };
        end else if (!stall_s3) begin
            rdata_s3    <= rdata_s2;
        end
    end

    // -- Initailization --
    generate
        if (!INITIALIZE) begin
            assign busy_s1 = 1'b0;
            assign we = wr_s3;
            assign waddr = index_s3;

        end else if (USE_INITIAL_BLOCK) begin
            assign busy_s1 = 1'b0;
            assign we = wr_s3;
            assign waddr = index_s3;

        end else begin
            // -- FSM (for initialization) --
            localparam  ST_WIDTH    = 2;
            localparam  ST_RST      = 2'd0,
                        ST_INIT     = 2'd1,
                        ST_READY    = 2'd2;

            reg [ST_WIDTH-1:0]                      state, state_next;
            reg [`PRGA_YAMI_CACHE_INDEX_WIDTH-1:0]  init_index;

            always @(posedge clk) begin
                if (~rst_n) begin
                    init_index  <= { `PRGA_YAMI_CACHE_INDEX_WIDTH {1'b0} };
                end else if (state == ST_INIT) begin
                    init_index  <= init_index + 1;
                end
            end

            always @(posedge clk) begin
                if (~rst_n) begin
                    state <= ST_RST;
                end else begin
                    state <= state_next;
                end
            end

            always @* begin
                state_next = state;

                case (state)
                    ST_RST:     state_next = ST_INIT;
                    ST_INIT:    state_next = &init_index ? ST_READY : ST_INIT;
                endcase
            end

            assign busy_s1 = state != ST_READY;
            assign we = state == ST_INIT || wr_s3;
            assign waddr = state == ST_INIT ? init_index : index_s3;
        end
    endgenerate

    genvar gv_way;
    generate
        for (gv_way = 0; gv_way < `PRGA_YAMI_CACHE_NUM_WAYS; gv_way = gv_way + 1) begin: g_way
            wire [`PRGA_YAMI_CACHE_TAG_WIDTH-1:0]    din_tmp;

            assign din_tmp = busy_s1 ? { `PRGA_YAMI_CACHE_TAG_WIDTH {1'b0} } :
                             gv_way == way_s3 ? wdata_s3 :
                                                rdata_s3[`PRGA_YAMI_CACHE_TAG_WIDTH * gv_way +: `PRGA_YAMI_CACHE_TAG_WIDTH];

            assign din[`PRGA_YAMI_CACHE_TAG_WIDTH * gv_way +: `PRGA_YAMI_CACHE_TAG_WIDTH] = din_tmp;
        end
    endgenerate

endmodule
