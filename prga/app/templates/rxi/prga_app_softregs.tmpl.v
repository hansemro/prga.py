// Automatically generated by PRGA's RTL generator
`timescale 1ns/1ps
`include "prga_app_softregs.vh"
{%- macro dwidth(name) -%} `PRGA_APP_SOFTREG_VAR_{{ name | upper }}_DATA_WIDTH {%- endmacro %}
{%- macro rstval(name) -%} `PRGA_APP_SOFTREG_VAR_{{ name | upper }}_RSTVAL {%- endmacro %}
{%- macro addr(name) -%} `PRGA_APP_SOFTREG_VAR_{{ name | upper }}_ADDR {%- endmacro %}

module prga_app_softregs #(
    parameter   PRQ_DEPTH_LOG2 = 3
) (
    input wire                                      clk
    , input wire                                    rst_n

    // == Val/Rdy Interface ===================================================
    , output reg                                    rxi_req_rdy
    , input wire                                    rxi_req_vld
    , input wire [`PRGA_APP_SOFTREG_ADDR_WIDTH-1:0] rxi_req_addr
    , input wire [`PRGA_APP_SOFTREG_DATA_BYTES-1:0] rxi_req_strb
    , input wire [`PRGA_APP_SOFTREG_DATA_WIDTH-1:0] rxi_req_data

    , input wire                                    rxi_resp_rdy
    , output reg                                    rxi_resp_vld
    , output reg                                    rxi_resp_sync
    , output reg [7:0]                              rxi_resp_syncaddr
    , output reg [`PRGA_APP_SOFTREG_DATA_WIDTH-1:0] rxi_resp_data

    // == Soft Register Ports =================================================
    {%- for name, r in module.softregs.regs.items() %}
        // {{ r.type_.name }} soft register: {{ name }}
        {%- if r.type_.is_const %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o

        {%- elif r.type_.is_kernel %}
    , input wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_i

        {%- elif r.type_.is_rdempty %}
    , input wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_i
    , input wire var_{{ name }}_empty
    , output wire var_{{ name }}_rd

        {%- elif r.type_.is_rdempty_la %}
    , input wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_i
    , input wire var_{{ name }}_empty
    , output wire var_{{ name }}_rd

        {%- elif r.type_.is_cbl_2stage %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o
    , input wire var_{{ name }}_ack
    , input wire var_{{ name }}_done

        {%- elif r.type_.is_vldrdy_rd %}
    , input wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_i
    , input wire var_{{ name }}_vld
    , output wire var_{{ name }}_rdy

        {%- elif r.type_.is_basic %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o

        {%- elif r.type_.is_pulse %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o

        {%- elif r.type_.is_pulse_ack %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o
    , input wire var_{{ name }}_ack

        {%- elif r.type_.is_decoupled %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o
    , input wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_i

        {%- elif r.type_.is_wrfull %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o
    , output wire var_{{ name }}_wr
    , input wire var_{{ name }}_full

        {%- elif r.type_.is_vldrdy_wr %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o
    , output wire var_{{ name }}_vld
    , input wire var_{{ name }}_rdy

        {%- elif r.type_.is_hsr_ififo %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o
    , output wire var_{{ name }}_wr
    , input wire var_{{ name }}_full

        {%- elif r.type_.is_hsr_ififo_vldrdy %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o
    , output wire var_{{ name }}_vld
    , input wire var_{{ name }}_rdy

        {%- elif r.type_.is_hsr_ofifo %}
    , input wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_i
    , input wire var_{{ name }}_wr
    , output wire var_{{ name }}_full

        {%- elif r.type_.is_hsr_tfifo %}
    , input wire var_{{ name }}_wr
    , output wire var_{{ name }}_full

        {%- elif r.type_.is_hsr_kernel %}
    , input wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_i

        {%- elif r.type_.is_hsr_basic %}
    , output wire [{{ dwidth(name) }} - 1:0] var_{{ name }}_o

        {%- elif not r.type_.is_reserved %}
        // Unsupported register type: {{ r.type_.name }}
        {%- endif %}
    {% endfor %}
    );

    // -----------------------------------------------------------------------
    // -- generate we/wmask --
    wire req_we;
    wire [`PRGA_APP_SOFTREG_DATA_WIDTH-1:0] req_wmask;

    assign req_we = |rxi_req_strb;

    genvar gv_mask;
    generate for (gv_mask = 0; gv_mask < `PRGA_APP_SOFTREG_DATA_BYTES; gv_mask = gv_mask + 1) begin: g_mask
        assign req_wmask[gv_mask*8+:8] = {8{rxi_req_strb[gv_mask]}};
    end endgenerate

    // -----------------------------------------------------------------------
    // -- assign internal IDs to the registers --
    {%- set regular_regs = module.softregs._filter_registers( exclude_types = ["reserved", "hsr_ofifo", "hsr_tfifo", "hsr_kernel"] ) %}
    {%- set num_regular_regs = regular_regs|length %}
    localparam  NUM_REGS        = {{ num_regular_regs }};
    localparam  G_REGID_WIDTH   = {{ num_regular_regs.bit_length() or 1 }};

    localparam  G_REGID_NONE    = {{ num_regular_regs.bit_length() or 1 }}'d0;
    {%- for r in regular_regs %}
    localparam  REGID_{{ r.name|upper }} = {{ num_regular_regs.bit_length() or 1 }}'d{{ loop.index }};
    {%- endfor %}

    wire [NUM_REGS:0] req_rdy, resp_vld;
    reg [NUM_REGS:0] resp_rdy, req_vld;
    wire [`PRGA_APP_SOFTREG_DATA_WIDTH-1:0] resp_data [0:NUM_REGS];

    assign req_rdy[G_REGID_NONE]    = 1'b1;
    assign resp_vld[G_REGID_NONE]   = 1'b1;
    assign resp_data[G_REGID_NONE]  = {`PRGA_APP_SOFTREG_DATA_WIDTH{1'b0}};

    // -- assign internal IDs to the HSRs --
    {%- set hsrs = module.softregs._filter_registers( include_types = ["hsr_ofifo", "hsr_tfifo", "hsr_kernel"] ) %}
    {%- set num_hsrs = hsrs|length %}
    localparam  NUM_HSRS        = {{ num_hsrs }};
    localparam  G_HSRID_WIDTH   = {{ num_hsrs.bit_length() or 1 }};

    localparam  G_HSRID_NONE    = {{ num_hsrs.bit_length() or 1 }}'d0;
    {%- for r in hsrs %}
    localparam  HSRID_{{ r.name|upper }} = {{ num_hsrs.bit_length() or 1 }}'d{{ loop.index }};
    {%- endfor %}

    wire [NUM_HSRS:0] sync_vld;
    reg [NUM_HSRS:0] sync_rdy;
    wire [`PRGA_APP_SOFTREG_DATA_WIDTH-1:0] sync_data [0:NUM_HSRS];

    assign sync_vld[G_HSRID_NONE]   = 1'b0;
    assign sync_data[G_HSRID_NONE]  = {`PRGA_APP_SOFTREG_DATA_WIDTH{1'b0}};

    // instantiate registers
    {%- for r in regular_regs %}
    // -----------------------------------------------------------------------
    // -- {{ r.type_.name }} soft register: {{ r.name }} --
    prga_app_softreg_{{ r.type_.name }} #(
        .DATA_WIDTH     ({{ dwidth(r.name) }})
        ,.RSTVAL        ({{ rstval(r.name) }})
    ) i_reg_{{ r.name }} (
        .clk            (clk)
        ,.rst_n         (rst_n)
        ,.req_rdy       (req_rdy[REGID_{{ r.name|upper }}])
        ,.req_vld       (req_vld[REGID_{{ r.name|upper }}])
        ,.req_we        (req_we)
        ,.req_wmask     (req_wmask)
        ,.req_data      (rxi_req_data)
        ,.resp_rdy      (resp_rdy[REGID_{{ r.name|upper }}])
        ,.resp_vld      (resp_vld[REGID_{{ r.name|upper }}])
        ,.resp_data     (resp_data[REGID_{{ r.name|upper }}][0+:{{ dwidth(r.name) }}])
        {%- if r.type_.is_const %}
        ,.var_o         (var_{{ r.name }}_o)

        {%- elif r.type_.is_kernel %}
        ,.var_i         (var_{{ r.name }}_i)

        {%- elif r.type_.is_rdempty %}
        ,.var_i         (var_{{ r.name }}_i)
        ,.var_empty     (var_{{ r.name }}_empty)
        ,.var_rd        (var_{{ r.name }}_rd)

        {%- elif r.type_.is_rdempty_la %}
        ,.var_i         (var_{{ r.name }}_i)
        ,.var_empty     (var_{{ r.name }}_empty)
        ,.var_rd        (var_{{ r.name }}_rd)

        {%- elif r.type_.is_cbl_2stage %}
        ,.var_o         (var_{{ r.name }}_o)
        ,.var_ack       (var_{{ r.name }}_ack)
        ,.var_done      (var_{{ r.name }}_done)

        {%- elif r.type_.is_vldrdy_rd %}
        ,.var_i         (var_{{ r.name }}_i)
        ,.var_vld       (var_{{ r.name }}_vld)
        ,.var_rdy       (var_{{ r.name }}_rdy)

        {%- elif r.type_.is_basic %}
        ,.var_o         (var_{{ r.name }}_o)

        {%- elif r.type_.is_pulse %}
        ,.var_o         (var_{{ r.name }}_o)

        {%- elif r.type_.is_pulse_ack %}
        ,.var_o         (var_{{ r.name }}_o)
        ,.var_ack       (var_{{ r.name }}_ack)

        {%- elif r.type_.is_decoupled %}
        ,.var_o         (var_{{ r.name }}_o)
        ,.var_i         (var_{{ r.name }}_i)

        {%- elif r.type_.is_wrfull %}
        ,.var_o         (var_{{ r.name }}_o)
        ,.var_wr        (var_{{ r.name }}_wr)
        ,.var_full      (var_{{ r.name }}_full)

        {%- elif r.type_.is_vldrdy_wr %}
        ,.var_o         (var_{{ r.name }}_o)
        ,.var_vld       (var_{{ r.name }}_vld)
        ,.var_rdy       (var_{{ r.name }}_rdy)

        {%- elif r.type_.is_hsr_ififo %}
        ,.var_o         (var_{{ r.name }}_o)
        ,.var_wr        (var_{{ r.name }}_wr)
        ,.var_full      (var_{{ r.name }}_full)

        {%- elif r.type_.is_hsr_ififo_vldrdy %}
        ,.var_o         (var_{{ r.name }}_o)
        ,.var_vld       (var_{{ r.name }}_vld)
        ,.var_rdy       (var_{{ r.name }}_rdy)

        {%- elif r.type_.is_hsr_basic %}
        ,.var_o         (var_{{ r.name }}_o)

        {%- endif %}
        );

    {% if r.width < 8 * (2 ** module.softregs.intf.data_bytes_log2) %}
    assign resp_data[REGID_{{ r.name|upper }}][`PRGA_APP_SOFTREG_DATA_WIDTH-1:{{ dwidth(r.name) }}] =
        { (`PRGA_APP_SOFTREG_DATA_WIDTH - {{ dwidth(r.name) }}) {1'b0} };
    {%- endif %}

    {% endfor %}
    {%- for r in hsrs %}
    // -----------------------------------------------------------------------
    // -- {{ r.type_.name }} soft register: {{ r.name }} --
    prga_app_softreg_{{ r.type_.name }} #(
        .DATA_WIDTH     ({{ dwidth(r.name) }})
        ,.RSTVAL        ({{ rstval(r.name) }})
    ) i_reg_{{ r.name }} (
        .clk            (clk)
        ,.rst_n         (rst_n)
        ,.sync_vld      (sync_vld[HSRID_{{ r.name|upper }}])
        ,.sync_rdy      (sync_rdy[HSRID_{{ r.name|upper }}])
        ,.sync_data     (sync_data[HSRID_{{ r.name|upper }}][0+:{{ dwidth(r.name) }}])
        {%- if r.type_.is_hsr_kernel %}
        ,.var_i         (var_{{ r.name }}_i)

        {%- elif r.type_.is_hsr_ofifo %}
        ,.var_i         (var_{{ r.name }}_i)
        ,.var_full      (var_{{ r.name }}_full)
        ,.var_wr        (var_{{ r.name }}_wr)

        {%- elif r.type_.is_hsr_tfifo %}
        ,.var_full      (var_{{ r.name }}_full)
        ,.var_wr        (var_{{ r.name }}_wr)

        {%- endif %}
        );

    {% if r.width < 8 * (2 ** module.softregs.intf.data_bytes_log2) %}
    assign sync_data[HSRID_{{ r.name|upper }}][`PRGA_APP_SOFTREG_DATA_WIDTH-1:{{ dwidth(r.name) }}] = 
        { (`PRGA_APP_SOFTREG_DATA_WIDTH - {{ dwidth(r.name) }}) {1'b0} };
    {%- endif %}

    {%- endfor %}

    // -----------------------------------------------------------------------
    // -- pending response queue --
    reg prq_rd;
    wire prq_full, prq_empty;
    reg [PRQ_DEPTH_LOG2:0] wptr, rptr;
    reg [G_REGID_WIDTH-1:0] prq [0:(1<<PRQ_DEPTH_LOG2)-1];
    reg [G_REGID_WIDTH-1:0] req_regid, resp_regid;

    always @(posedge clk) begin
        if (~rst_n) begin
            wptr <= { (PRQ_DEPTH_LOG2+1) {1'b0} };
            rptr <= { (PRQ_DEPTH_LOG2+1) {1'b0} };
            resp_regid <= { (G_REGID_WIDTH+1) {1'b0} };
        end else begin
            if (prq_rd && !prq_empty) begin
                rptr <= rptr + 1;
                resp_regid <= prq[rptr[0+:PRQ_DEPTH_LOG2]];
            end

            if (rxi_req_rdy && rxi_req_vld && !prq_full) begin
                prq[wptr[0+:PRQ_DEPTH_LOG2]] <= req_regid;
                wptr <= wptr + 1;
            end
        end
    end

    assign prq_empty = wptr == rptr;
    assign prq_full = wptr == {~rptr[PRQ_DEPTH_LOG2], rptr[0+:PRQ_DEPTH_LOG2]};

    // -----------------------------------------------------------------------
    // -- request distribution --
    always @* begin
        req_regid = G_REGID_NONE;

        case (rxi_req_addr)
            {%- for r in regular_regs %}
            {{ addr(r.name) }}: begin
                req_regid = REGID_{{ r.name|upper }};
            end
            {%- endfor %}
        endcase
    end

    always @* begin
        req_vld = { (NUM_REGS + 1) {1'b0} };

        if (rxi_req_vld && !prq_full)
            req_vld[req_regid] = 1'b1;
    end

    always @* begin
        rxi_req_rdy = 1'b0;

        if (!prq_full)
            rxi_req_rdy = req_rdy[req_regid];
    end

    // -----------------------------------------------------------------------
    // -- sync arbitration --
    // low throughput but low resource usage and complexity
    reg [G_HSRID_WIDTH-1:0]     sync_arb;
    always @(posedge clk) begin
        if (~rst_n) begin
            sync_arb <= G_HSRID_NONE;
        end else if (!sync_vld[sync_arb] || sync_rdy[sync_arb]) begin
            if (sync_arb == NUM_HSRS)
                sync_arb <= 0;
            else
                sync_arb <= sync_arb + 1;
        end
    end

    // -----------------------------------------------------------------------
    // -- response collection --
    reg resp_regid_vld;

    always @(posedge clk) begin
        if (~rst_n) begin
            resp_regid_vld <= 1'b0;
        end else if (prq_rd && !prq_empty) begin
            resp_regid_vld <= 1'b1;
        end else if (rxi_resp_vld && !rxi_resp_sync && rxi_resp_rdy) begin
            resp_regid_vld <= 1'b0;
        end
    end

    always @* begin
        rxi_resp_vld = 1'b0;
        rxi_resp_sync = 1'b0;
        rxi_resp_syncaddr = 8'h0;
        rxi_resp_data = { `PRGA_APP_SOFTREG_DATA_WIDTH {1'b0} };
        resp_rdy = { (NUM_REGS + 1) {1'b0} };
        sync_rdy = { (NUM_HSRS + 1) {1'b0} };

        if (resp_regid_vld && resp_vld[resp_regid]) begin
            rxi_resp_vld = 1'b1;
            rxi_resp_data = resp_data[resp_regid];
            resp_rdy[resp_regid] = rxi_resp_rdy;
        end else if (sync_vld[sync_arb]) begin
            rxi_resp_vld = 1'b1;
            rxi_resp_sync = 1'b1;
            rxi_resp_data = sync_data[sync_arb];
            sync_rdy[sync_arb] = rxi_resp_rdy;

            case (sync_arb)
                {%- for r in hsrs %}
                HSRID_{{ r.name|upper }}: begin
                    rxi_resp_syncaddr = {{ addr(r.name) }};
                end
                {%- endfor %}
            endcase
        end
    end

    always @* begin
        prq_rd = !resp_regid_vld || (rxi_resp_vld && !rxi_resp_sync && rxi_resp_rdy);
    end

endmodule
