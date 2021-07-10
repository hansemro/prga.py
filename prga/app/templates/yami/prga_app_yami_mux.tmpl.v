// Automatically generated by PRGA's RTL generator
`include "prga_yami.vh"

/*
* Memory muxer.
*
*   Mux memory requests.
*/

module {{ module.name }} #(
    parameter   PRQ_DEPTH_LOG2  = 3
) (
    input wire                                      clk
    , input wire                                    rst_n

    // == Sources ============================================================
    {%- for i in range(module.num_srcs) %}
    , output reg                                    src{{ i }}_fmc_rdy
    , input wire                                    src{{ i }}_fmc_vld
    , input wire [`PRGA_YAMI_REQTYPE_WIDTH-1:0]     src{{ i }}_fmc_type
    , input wire [`PRGA_YAMI_SIZE_WIDTH-1:0]        src{{ i }}_fmc_size
    , input wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]    src{{ i }}_fmc_addr
    , input wire [`PRGA_YAMI_FMC_DATA_WIDTH-1:0]    src{{ i }}_fmc_data

    , input wire                                    src{{ i }}_mfc_rdy
    , output reg                                    src{{ i }}_mfc_vld
    , output wire [`PRGA_YAMI_RESPTYPE_WIDTH-1:0]   src{{ i }}_mfc_type
    // , output wire [`PRGA_YAMI_MFC_ADDR_WIDTH-1:0]   src{{ i }}_mfc_addr
    , output wire [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]   src{{ i }}_mfc_data

    {% endfor %}
    // == Destination ========================================================
    , input wire                                    dst_fmc_rdy
    , output reg                                    dst_fmc_vld
    , output reg [`PRGA_YAMI_REQTYPE_WIDTH-1:0]     dst_fmc_type
    , output reg [`PRGA_YAMI_SIZE_WIDTH-1:0]        dst_fmc_size
    , output reg [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]    dst_fmc_addr
    , output reg [`PRGA_YAMI_FMC_DATA_WIDTH-1:0]    dst_fmc_data

    , output reg                                    dst_mfc_rdy
    , input wire                                    dst_mfc_vld
    , input wire [`PRGA_YAMI_RESPTYPE_WIDTH-1:0]    dst_mfc_type
    // , input wire [`PRGA_YAMI_MFC_ADDR_WIDTH-1:0]    dst_mfc_addr
    , input wire [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]    dst_mfc_data

    );

    localparam  NUM_SRC         = {{ module.num_srcs }};
    localparam  SRCID_WIDTH     = {{ (module.num_srcs - 1).bit_length() }};
    localparam  NUM_SRC_ALIGNED = 1 << SRCID_WIDTH;

    reg [SRCID_WIDTH-1:0]   req_srcid, req_srcid_next;
    wire [SRCID_WIDTH-1:0]  resp_srcid;

    // == Pending Response Queue =============================================
    wire                    prq_full, prq_empty;
    reg                     prq_rd, prq_wr;

    prga_fifo #(
        .DATA_WIDTH     (SRCID_WIDTH)
        ,.DEPTH_LOG2    (PRQ_DEPTH_LOG2)
        ,.LOOKAHEAD     (1)
    ) i_prq (
        .clk            (clk)
        ,.rst           (~rst_n)
        ,.full          (prq_full)
        ,.wr            (prq_wr)
        ,.din           (req_srcid)
        ,.empty         (prq_empty)
        ,.rd            (prq_rd)
        ,.dout          (resp_srcid)
        );

    // == Request Arbitration ================================================
    wire [NUM_SRC_ALIGNED - 1:0] fmc_src_vld, fmc_src_vld_shifted;
    {%- for i in range( 2 ** (module.num_srcs-1).bit_length() ) %}
        {%- if i < module.num_srcs %}
    assign fmc_src_vld[{{ i }}] = src{{ i }}_fmc_vld;
        {%- else %}
    assign fmc_src_vld[{{ i }}] = 1'b0;
        {%- endif %}
    {%- endfor %}
    assign fmc_src_vld_shifted = {fmc_src_vld, fmc_src_vld} >> req_srcid;

    always @* begin
        req_srcid_next = req_srcid;
        {%- set ifjoiner = joiner("end else ") %}
        {% for i in range( 1, 2 ** (module.num_srcs-1).bit_length() ) %}
        {{ ifjoiner() }}if (fmc_src_vld_shifted[{{ i }}]) begin
            req_srcid_next = req_srcid + {{ i }};
        {%- endfor %}
        end
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            req_srcid <= { SRCID_WIDTH {1'b0} };
        end else if (!dst_fmc_vld || dst_fmc_rdy) begin
            req_srcid <= req_srcid_next;
        end
    end

    // == Request Processing =================================================
    always @* begin
        dst_fmc_vld = 1'b0;
        dst_fmc_type = `PRGA_YAMI_REQTYPE_NONE;
        dst_fmc_size = `PRGA_YAMI_SIZE_FULL;
        dst_fmc_addr = { `PRGA_YAMI_FMC_ADDR_WIDTH {1'b0} };
        dst_fmc_data = { `PRGA_YAMI_FMC_DATA_WIDTH {1'b0} };
        {%- for i in range(module.num_srcs) %}
        src{{ i }}_fmc_rdy = 1'b0;
        {%- endfor %}
        prq_wr = 1'b0;

        case (req_srcid)
            {%- for i in range(module.num_srcs) %}
            {{ (module.num_srcs - 1).bit_length() }}'d{{ i }}: begin
                dst_fmc_vld = src{{ i }}_fmc_vld && !prq_full;
                dst_fmc_type = src{{ i }}_fmc_type;
                dst_fmc_size = src{{ i }}_fmc_size;
                dst_fmc_addr = src{{ i }}_fmc_addr;
                dst_fmc_data = src{{ i }}_fmc_data;
                src{{ i }}_fmc_rdy = dst_fmc_rdy && !prq_full;
                prq_wr = src{{ i }}_fmc_vld && dst_fmc_rdy;
            end
            {%- endfor %}
        endcase
    end

    // == Response Distribution ==============================================
    {%- for i in range(module.num_srcs) %}
    assign src{{ i }}_mfc_type = dst_mfc_type;
    // assign src{{ i }}_mfc_addr = dst_mfc_addr;
    assign src{{ i }}_mfc_data = dst_mfc_data;
    {% endfor %}

    always @* begin
        {%- for i in range(module.num_srcs) %}
        src{{ i }}_mfc_vld = 1'b0;
        {%- endfor %}
        dst_mfc_rdy = 1'b0;
        prq_rd = 1'b0;

        if (!prq_empty) begin
            case (resp_srcid)
                {%- for i in range(module.num_srcs) %}
                {{ (module.num_srcs - 1).bit_length() }}'d{{ i }}: begin
                    src{{ i }}_mfc_vld = dst_mfc_vld;
                    dst_mfc_rdy = src{{ i }}_mfc_rdy;
                    prq_rd = dst_mfc_vld && src{{ i }}_mfc_rdy;
                end
                {%- endfor %}
            endcase
        end
    end

endmodule
