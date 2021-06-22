// Automatically generated by PRGA's RTL generator
`include "prga_yami.vh"

/*
* Memory demuxer.
*
*   Distribute memory requests based on the address.
*/

module {{ module.name }} #(
    parameter   PRQ_DEPTH_LOG2  = 3
) (
    input wire                                      clk
    , input wire                                    rst_n

    // == Source =============================================================
    , output reg                                    src_fmc_rdy
    , input wire                                    src_fmc_vld
    , input wire [`PRGA_YAMI_REQTYPE_WIDTH-1:0]     src_fmc_type
    , input wire [`PRGA_YAMI_SIZE_WIDTH-1:0]        src_fmc_size
    , input wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]    src_fmc_addr
    , input wire [`PRGA_YAMI_FMC_DATA_WIDTH-1:0]    src_fmc_data

    , input wire                                    src_mfc_rdy
    , output reg                                    src_mfc_vld
    , output reg [`PRGA_YAMI_RESPTYPE_WIDTH-1:0]    src_mfc_type
    // , output reg [`PRGA_YAMI_MFC_ADDR_WIDTH-1:0]    src_mfc_addr
    , output reg [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]    src_mfc_data

    // == Destinations =======================================================
    {%- for i in range(module.num_dsts) %}
    , input wire                                    dst{{ i }}_fmc_rdy
    , output wire                                   dst{{ i }}_fmc_vld
    , output wire [`PRGA_YAMI_REQTYPE_WIDTH-1:0]    dst{{ i }}_fmc_type
    , output wire [`PRGA_YAMI_SIZE_WIDTH-1:0]       dst{{ i }}_fmc_size
    , output wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]   dst{{ i }}_fmc_addr
    , output wire [`PRGA_YAMI_FMC_DATA_WIDTH-1:0]   dst{{ i }}_fmc_data

    , output reg                                    dst{{ i }}_mfc_rdy
    , input wire                                    dst{{ i }}_mfc_vld
    , input wire [`PRGA_YAMI_RESPTYPE_WIDTH-1:0]    dst{{ i }}_mfc_type
    // , input wire [`PRGA_YAMI_MFC_ADDR_WIDTH-1:0]    dst{{ i }}_mfc_addr
    , input wire [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]    dst{{ i }}_mfc_data

    {% endfor %}
    );

    localparam  DEMUX_ADDR_LOW  = {{ module.demux_addr_low }};
    localparam  DEMUX_ADDR_HIGH = {{ module.demux_addr_high }};

    localparam  NUM_DST         = {{ module.num_dsts }};
    localparam  DSTID_WIDTH     = {{ (module.num_dsts - 1).bit_length() }};

    reg [DSTID_WIDTH-1:0]   req_dstid;
    wire [DSTID_WIDTH-1:0]  resp_dstid;

    // == Pending Response Queue =============================================
    wire                    prq_full, prq_empty;
    reg                     prq_rd, prq_wr;

    prga_fifo #(
        .DATA_WIDTH     (DSTID_WIDTH)
        ,.DEPTH_LOG2    (PRQ_DEPTH_LOG2)
        ,.LOOKAHEAD     (1)
    ) i_prq (
        .clk            (clk)
        ,.rst           (~rst_n)
        ,.full          (prq_full)
        ,.wr            (prq_wr)
        ,.din           (req_dstid)
        ,.empty         (prq_empty)
        ,.rd            (prq_rd)
        ,.dout          (resp_dstid)
        );

    // == Request Distribution ===============================================
    wire [NUM_DST - 1:0]    fmc_dst_rdy;

    always @* begin
        req_dstid = { DSTID_WIDTH {1'b0} };

        case (src_fmc_addr[DEMUX_ADDR_HIGH : DEMUX_ADDR_LOW])
            {%- for i in range(2 ** (module.demux_addr_high - module.demux_addr_low + 1)) %}
            {{ module.demux_addr_high - module.demux_addr_low + 1 }}'d{{ i }}: req_dstid = {{ i % module.num_dsts }};
            {%- endfor %}
        endcase
    end

    always @* begin
        prq_wr = src_fmc_vld && fmc_dst_rdy[req_dstid];
        src_fmc_rdy = !prq_full && fmc_dst_rdy[req_dstid];
    end
    {% for i in range(module.num_dsts) %}
    // destination No. {{ i }}
    assign fmc_dst_rdy[{{ i }}] = dst{{ i }}_fmc_rdy;
    assign dst{{ i }}_fmc_vld = req_dstid == {{ i }} && src_fmc_vld && !prq_full;
    assign dst{{ i }}_fmc_type = src_fmc_type;
    assign dst{{ i }}_fmc_size = src_fmc_size;
    assign dst{{ i }}_fmc_addr = src_fmc_addr;
    assign dst{{ i }}_fmc_data = src_fmc_data;

    {% endfor %}

    // == Response Muxing ====================================================
    always @* begin
        src_mfc_vld = 1'b0;
        src_mfc_type = `PRGA_YAMI_RESPTYPE_NONE;
        // src_mfc_addr = { `PRGA_YAMI_MFC_ADDR_WIDTH {1'b0} };
        src_mfc_data = { `PRGA_YAMI_MFC_DATA_WIDTH {1'b0} };
        prq_rd = 1'b0;
        {% for i in range(module.num_dsts) %}
        dst{{ i }}_mfc_rdy = 1'b0;
        {%- endfor %}

        if (!prq_empty) begin
            case (resp_dstid)
                {%- for i in range(module.num_dsts) %}
                {{ (module.num_dsts - 1).bit_length() }}'d{{ i }}: begin
                    src_mfc_vld = dst{{ i }}_mfc_vld;
                    src_mfc_type = dst{{ i }}_mfc_type;
                    // src_mfc_addr = dst{{ i }}_mfc_addr;
                    src_mfc_data = dst{{ i }}_mfc_data;
                    dst{{ i }}_mfc_rdy = src_mfc_rdy;
                    prq_rd = dst{{ i }}_mfc_vld && src_mfc_rdy;
                end
                {%- endfor %}
            endcase
        end
    end

endmodule
