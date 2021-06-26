// Automatically generated by PRGA's RTL generator

/*
* RXI in system clock domain (frontend).
*/

`include "prga_rxi.vh"
`default_nettype none

module prga_rxi_fe #(
    parameter   HSR_FIFO_DEPTH_LOG2 = 3
) (
    // -- Interface Ctrl -----------------------------------------------------
    input wire                                          clk
    , input wire                                        rst_n

    // -- Generate Application Clock -----------------------------------------
    , output wire                                       aclk
    , output wire                                       arst_n

    // -- System Slave Interface ---------------------------------------------
    , output reg                                        s_req_rdy
    , input wire                                        s_req_vld
    , input wire [`PRGA_RXI_ADDR_WIDTH-1:0]             s_req_addr
    , input wire [`PRGA_RXI_DATA_BYTES-1:0]             s_req_strb
    , input wire [`PRGA_RXI_DATA_WIDTH-1:0]             s_req_data

    , input wire                                        s_resp_rdy
    , output reg                                        s_resp_vld
    , output reg [`PRGA_RXI_DATA_WIDTH-1:0]             s_resp_data

    // -- Programming Master Interface ---------------------------------------
    , output reg                                        prog_rst_n
    , input wire                                        prog_done

    , input wire                                        prog_req_rdy
    , output reg                                        prog_req_vld
    , output wire [`PRGA_RXI_PROG_REG_ID_WIDTH-1:0]     prog_req_addr
    , output wire [`PRGA_RXI_DATA_BYTES-1:0]            prog_req_strb
    , output wire [`PRGA_RXI_DATA_WIDTH-1:0]            prog_req_data

    , output reg                                        prog_resp_rdy
    , input wire                                        prog_resp_vld
    , input wire                                        prog_resp_err
    , input wire [`PRGA_RXI_DATA_WIDTH-1:0]             prog_resp_data

    // -- FE -> BE Async FIFO ------------------------------------------------
    , input wire                                        f2b_full
    , output reg                                        f2b_wr
    , output reg [`PRGA_RXI_F2B_ELEM_WIDTH-1:0]         f2b_data

    // -- BE -> FE Async FIFO ------------------------------------------------
    , output reg                                        b2f_rd
    , input wire                                        b2f_empty
    , input wire [`PRGA_RXI_B2F_ELEM_WIDTH-1:0]         b2f_data
    );

    // =======================================================================
    // -- Ctrl Registers -----------------------------------------------------
    // =======================================================================

    // -- frontend status --
    reg [`PRGA_RXI_STATUS_WIDTH-1:0]    status;
    reg event_activate, event_deactivate, event_app_error;

    always @(posedge clk) begin
        if (~rst_n) begin
            status  <= `PRGA_RXI_STATUS_RESET;
        end else begin
            case (status)
                `PRGA_RXI_STATUS_RESET:
                    status  <= `PRGA_RXI_STATUS_PROGRAMMING;

                `PRGA_RXI_STATUS_PROGRAMMING:
                    status  <= (prog_resp_err && prog_resp_vld && prog_resp_rdy) ? `PRGA_RXI_STATUS_PROG_ERROR :
                               prog_done ? `PRGA_RXI_STATUS_STANDBY : status;

                `PRGA_RXI_STATUS_PROG_ERROR:
                    status  <= ~prog_rst_n ? `PRGA_RXI_STATUS_PROGRAMMING : status;

                `PRGA_RXI_STATUS_STANDBY:
                    status  <= event_activate ? `PRGA_RXI_STATUS_ACTIVE :
                               ~prog_rst_n ? `PRGA_RXI_STATUS_PROGRAMMING : status;

                `PRGA_RXI_STATUS_APP_ERROR:
                    status  <= event_activate ? `PRGA_RXI_STATUS_ACTIVE :
                               event_deactivate ? `PRGA_RXI_STATUS_STANDBY : status;

                `PRGA_RXI_STATUS_ACTIVE:
                    status  <= event_app_error ? `PRGA_RXI_STATUS_APP_ERROR :
                               event_deactivate ? `PRGA_RXI_STATUS_STANDBY : status;
            endcase
        end
    end

    wire rxi_active;
    assign rxi_active = status == `PRGA_RXI_STATUS_ACTIVE;

    // -- error code --
    reg [`PRGA_RXI_DATA_WIDTH-1:0]      errcode;

    always @(posedge clk) begin
        if (~rst_n) begin
            errcode <= `PRGA_RXI_ERRCODE_NONE;
        end else if (~prog_rst_n || event_activate) begin
            errcode <= `PRGA_RXI_ERRCODE_NONE;
        end else if (errcode == `PRGA_RXI_ERRCODE_NONE) begin
            if (prog_resp_err && prog_resp_vld && prog_resp_rdy) begin
                errcode <= prog_resp_data;
            end else if (event_app_error) begin
                errcode <= b2f_data[`PRGA_RXI_B2F_DATA_INDEX];
            end
        end
    end

    // -- clock divider --
    reg                                 clkdiv_factor_we;
    wire [`PRGA_RXI_CLKDIV_WIDTH-1:0]   clkdiv_factor;

    prga_clkdiv #(
        .COUNTER_WIDTH  (`PRGA_RXI_CLKDIV_WIDTH)
    ) i_clkdiv (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.div_factor_i      (s_req_data[0+:`PRGA_RXI_CLKDIV_WIDTH])
        ,.div_factor_we_i   (clkdiv_factor_we)
        ,.div_factor_o      (clkdiv_factor)
        ,.divclk            (aclk)
        );

    // -- arst_n --
    prga_sync_basic #(
        .DATA_WIDTH (1)
        ,.STAGE     (2)
    ) i_rst_sync (
        .idata              (rst_n)
        ,.oclk              (aclk)
        ,.odata             (arst_n)
        );

    // -- soft register timeout --
    reg                             timeout_limit_we;
    wire [`PRGA_RXI_DATA_WIDTH-1:0] timeout_limit;

    prga_byteaddressable_reg #(
        .NUM_BYTES  (`PRGA_RXI_DATA_BYTES)
    ) i_timeout_limit (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.wr                (timeout_limit_we)
        ,.mask              (s_req_strb)
        ,.din               (s_req_data)
        ,.dout              (timeout_limit)
        );

    // -- YAMI enable state --
    reg                             yami_enable_we;
    wire [`PRGA_RXI_DATA_WIDTH-1:0] yami_enable;

    prga_byteaddressable_reg #(
        .NUM_BYTES  (`PRGA_RXI_DATA_BYTES)
    ) i_yami_enable (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.wr                (yami_enable_we)
        ,.mask              (s_req_strb)
        ,.din               (s_req_data)
        ,.dout              (yami_enable)
        );

    // -- prog reset --
    reg                             prog_rst_countdown_rst;
    wire [`PRGA_RXI_DATA_WIDTH-1:0] prog_rst_countdown;

    prga_byteaddressable_reg #(
        .NUM_BYTES  (`PRGA_RXI_DATA_BYTES)
    ) i_prog_rst (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.wr                (prog_rst_countdown_rst || prog_rst_countdown > 0)
        ,.mask              (prog_rst_countdown_rst ? s_req_strb :
                                                      {`PRGA_RXI_DATA_BYTES {1'b1} })
        ,.din               (prog_rst_countdown_rst ? s_req_data :
                                                      (prog_rst_countdown - 1))
        ,.dout              (prog_rst_countdown)
        );

    always @(posedge clk) begin
        if (~rst_n) begin
            prog_rst_n           <= 1'b0;
        end else if (prog_rst_countdown_rst) begin
            prog_rst_n           <= 1'b0;
        end else if (prog_rst_countdown == 0) begin
            prog_rst_n           <= 1'b1;
        end
    end

    // -- scratchpad registers --
    wire [`PRGA_RXI_SCRATCHPAD_ID_WIDTH-1:0]    scratchpad_id;
    reg [`PRGA_RXI_DATA_BYTES-1:0]              scratchpad_strb;
    wire [`PRGA_RXI_DATA_WIDTH-1:0]             scratchpads [0:`PRGA_RXI_NUM_SCRATCHPADS-1];

    genvar gv_scratchpad;
    generate
        for (gv_scratchpad = 0;
            gv_scratchpad < `PRGA_RXI_NUM_SCRATCHPADS;
            gv_scratchpad = gv_scratchpad + 1
        ) begin: g_scratchpad

            prga_byteaddressable_reg #(
                .NUM_BYTES  (`PRGA_RXI_DATA_BYTES)
            ) i_scractchpad (
                .clk        (clk)
                ,.rst       (~rst_n)
                ,.wr        (scratchpad_id == gv_scratchpad)
                ,.mask      (scratchpad_strb)
                ,.din       (s_req_data)
                ,.dout      (scratchpads[gv_scratchpad])
                );
        end
    endgenerate

    // -- Hardware-sync'ed registers: input FIFO --
    reg [`PRGA_RXI_NUM_HSR_IQS-1:0]         iq_wr;
    wire [`PRGA_RXI_NUM_HSR_IQS-1:0]        iq_full;
    wire [`PRGA_RXI_HSR_IQ_ID_WIDTH-1:0]    iq_id;
    wire                                    iq_vld;
    wire [`PRGA_RXI_DATA_WIDTH-1:0]         iq_dout;
    reg                                     iq_rdy;

    prga_rxi_fe_iq #(
        .FIFO_DEPTH_LOG2    (HSR_FIFO_DEPTH_LOG2)
    ) i_iq (
        .clk                (clk)
        ,.rst               (~rst_n || ~rxi_active)
        ,.wr                (iq_wr)
        ,.din               (s_req_data)
        ,.full              (iq_full)
        ,.rdy               (iq_rdy)
        ,.id                (iq_id)
        ,.vld               (iq_vld)
        ,.data              (iq_dout)
        );

    // -- Hardware-sync'ed registers: output FIFO -- 
    reg [`PRGA_RXI_NUM_HSR_OQS-1:0]         oq_rd, oq_wr;
    wire [`PRGA_RXI_NUM_HSR_OQS-1:0]        oq_full, oq_empty;
    wire [`PRGA_RXI_DATA_WIDTH-1:0]         oq_dout [0:`PRGA_RXI_NUM_HSR_OQS-1];

    genvar gv_oq;
    generate
        for (gv_oq = 0; gv_oq < `PRGA_RXI_NUM_HSR_OQS; gv_oq = gv_oq + 1) begin: g_oq
            prga_fifo #(
                .DEPTH_LOG2     (HSR_FIFO_DEPTH_LOG2)
                ,.DATA_WIDTH    (`PRGA_RXI_DATA_WIDTH)
                ,.LOOKAHEAD     (1)
            ) i_oq (
                .clk            (clk)
                ,.rst           (~rst_n || ~rxi_active)
                ,.wr            (oq_wr[gv_oq])
                ,.din           (b2f_data[`PRGA_RXI_B2F_DATA_INDEX])
                ,.full          (oq_full[gv_oq])
                ,.rd            (oq_rd[gv_oq])
                ,.empty         (oq_empty[gv_oq])
                ,.dout          (oq_dout[gv_oq])
                );
        end
    endgenerate

    // -- Hardware-sync'ed registers: output token FIFO --
    reg [`PRGA_RXI_NUM_HSR_TQS-1:0]         tq_rd, tq_wr;
    wire [`PRGA_RXI_NUM_HSR_TQS-1:0]        tq_full, tq_empty;

    genvar gv_tq;
    generate
        for (gv_tq = 0; gv_tq < `PRGA_RXI_NUM_HSR_TQS; gv_tq = gv_tq + 1) begin: g_tq
            prga_tokenfifo #(
                .DEPTH_LOG2     (HSR_FIFO_DEPTH_LOG2)
            ) i_tq (
                .clk            (clk)
                ,.rst           (~rst_n || ~rxi_active)
                ,.wr            (tq_wr[gv_tq])
                ,.full          (tq_full[gv_tq])
                ,.rd            (tq_rd[gv_tq])
                ,.empty         (tq_empty[gv_tq])
                );
        end
    endgenerate

    // -- Hardware-sync'ed registers: plain --
    reg                                     phsr_vld, phsr_b2f_sync, phsr_f2b_rdy;
    wire                                    phsr_f2b_vld;
    wire [`PRGA_RXI_HSR_PLAIN_ID_WIDTH-1:0] phsr_id, phsr_b2f_id, phsr_f2b_id;
    wire [`PRGA_RXI_DATA_WIDTH-1:0]         phsr_dout, phsr_f2b_data;

    prga_rxi_fe_phsr i_phsr (
        .clk                    (clk)
        ,.rst_n                 (rst_n && rxi_active)
        ,.s_req_vld             (phsr_vld)
        ,.s_req_id              (phsr_id)
        ,.s_req_strb            (s_req_strb)
        ,.s_req_din             (s_req_data)
        ,.s_resp_dout           (phsr_dout)
        ,.a_sync                (phsr_b2f_sync)
        ,.a_id                  (phsr_b2f_id)
        ,.a_data                (b2f_data[`PRGA_RXI_B2F_DATA_INDEX])
        ,.m_rdy                 (phsr_f2b_rdy)
        ,.m_id                  (phsr_f2b_id)
        ,.m_vld                 (phsr_f2b_vld)
        ,.m_data                (phsr_f2b_data)
        );

    // =======================================================================
    // -- Pending Reponses Queue ---------------------------------------------
    // =======================================================================
    localparam  PRQ_TOKEN_WIDTH = 2;
    localparam  PRQ_TOKEN_PROG  = 2'd0,     // pending response from the programming interface
                PRQ_TOKEN_B2F   = 2'd1,     // pending response from the backend
                PRQ_TOKEN_BOGUS = 2'd2,     // pending response with bogus data
                PRQ_TOKEN_RB    = 2'd3;     // pending response from the response buffer

    reg                         prq_rd, prq_wr;
    reg [PRQ_TOKEN_WIDTH-1:0]   prq_din;
    wire                        prq_full, prq_empty;
    wire [PRQ_TOKEN_WIDTH-1:0]  prq_dout;

    prga_fifo #(
        .DEPTH_LOG2     (6)
        ,.DATA_WIDTH    (PRQ_TOKEN_WIDTH)
        ,.LOOKAHEAD     (1)
    ) i_prq (
        .clk            (clk)
        ,.rst           (~rst_n)
        ,.full          (prq_full)
        ,.wr            (prq_wr)
        ,.din           (prq_din)
        ,.empty         (prq_empty)
        ,.rd            (prq_rd)
        ,.dout          (prq_dout)
        );

    reg                             rb_rd, rb_wr;
    reg [`PRGA_RXI_DATA_WIDTH-1:0]  rb_din;
    wire                            rb_full, rb_empty;
    wire [`PRGA_RXI_DATA_WIDTH-1:0] rb_dout;

    prga_fifo #(
        .DEPTH_LOG2     (3)     // not a lot of space
        ,.DATA_WIDTH    (`PRGA_RXI_DATA_WIDTH)
        ,.LOOKAHEAD     (1)
    ) i_rb (
        .clk            (clk)
        ,.rst           (~rst_n)
        ,.full          (rb_full)
        ,.wr            (rb_wr)
        ,.din           (rb_din)
        ,.empty         (rb_empty)
        ,.rd            (rb_rd)
        ,.dout          (rb_dout)
        );

    // =======================================================================
    // -- Request ------------------------------------------------------------
    // =======================================================================

    // -- decode request address --
    wire [`PRGA_RXI_HSRID_WIDTH-1:0]        hsr_id;
    wire [`PRGA_RXI_HSR_OQ_ID_WIDTH-1:0]    oq_id;
    wire [`PRGA_RXI_HSR_TQ_ID_WIDTH-1:0]    tq_id;

    assign hsr_id = s_req_addr[0+:`PRGA_RXI_HSRID_WIDTH];

    assign prog_req_addr = s_req_addr[0+:`PRGA_RXI_PROG_REG_ID_WIDTH];
    assign prog_req_strb = s_req_strb;
    assign prog_req_data = s_req_data;

    assign scratchpad_id = s_req_addr[0+:`PRGA_RXI_SCRATCHPAD_ID_WIDTH];
    assign oq_id = s_req_addr[0+:`PRGA_RXI_HSR_OQ_ID_WIDTH];
    assign tq_id = s_req_addr[0+:`PRGA_RXI_HSR_TQ_ID_WIDTH];
    assign phsr_id = s_req_addr[0+:`PRGA_RXI_HSR_PLAIN_ID_WIDTH];

    // -- tasks --
    task automatic forward_f2b;
        begin
            s_req_rdy = !f2b_full && !prq_full;
            f2b_wr = s_req_vld && !prq_full;
            f2b_data[`PRGA_RXI_F2B_STRB_INDEX] = s_req_strb;
            f2b_data[`PRGA_RXI_F2B_REGID_INDEX] = s_req_addr;
            f2b_data[`PRGA_RXI_F2B_DATA_INDEX] = s_req_data;
            prq_wr = s_req_vld && !f2b_full;
            prq_din = PRQ_TOKEN_B2F;
        end
    endtask

    task automatic buffer_bogus;
        begin
            s_req_rdy = !prq_full;
            prq_wr = s_req_vld;
            prq_din = PRQ_TOKEN_BOGUS;
        end
    endtask

    task automatic buffer_response;
        input [`PRGA_RXI_DATA_WIDTH-1:0] resp;
        begin
            s_req_rdy = !prq_full && !rb_full;
            prq_wr = s_req_vld;
            prq_din = PRQ_TOKEN_RB;
            rb_wr = s_req_vld;
            rb_din = resp;
        end
    endtask

    // -- main process --
    always @* begin
        s_req_rdy = 1'b0;
        prog_req_vld = 1'b0;
        f2b_wr = 1'b0;
        f2b_data = { `PRGA_RXI_F2B_ELEM_WIDTH {1'b0} };
        event_activate = 1'b0;
        event_deactivate = 1'b0;
        clkdiv_factor_we = 1'b0;
        timeout_limit_we = 1'b0;
        yami_enable_we = 1'b0;
        prog_rst_countdown_rst = 1'b0;
        scratchpad_strb = { `PRGA_RXI_DATA_BYTES {1'b0} };
        iq_wr = { `PRGA_RXI_NUM_HSR_IQS {1'b0} };
        iq_rdy = 1'b0;
        oq_rd = { `PRGA_RXI_NUM_HSR_OQS {1'b0} };
        tq_rd = { `PRGA_RXI_NUM_HSR_TQS {1'b0} };
        phsr_vld = 1'b0;
        phsr_f2b_rdy = 1'b0;
        prq_wr = 1'b0;
        prq_din = PRQ_TOKEN_PROG;
        rb_wr = 1'b0;
        rb_din = { `PRGA_RXI_DATA_WIDTH {1'b0} };

        // -- status --
        // ------------
        if (s_req_addr == `PRGA_RXI_NSRID_STATUS) begin

            // store needs to be forwarded into the application clock domain
            if (s_req_strb[0]) begin
                forward_f2b;

                // Notes:
                //
                //  1. activate should only be issued when the status is
                //     STANBY or APP_ERROR.
                //  2. deactivate should only be issued when the status is
                //     ACTIVE or APP_ERROR.
                //  3. deactivate takes effect in the system clock domain
                //     immediately, and is forwarded into the application
                //     domain. If there are pending responses in the application
                //     clock domain, they will be flushed an completed with
                //     bogus data
                if (s_req_vld && !f2b_full && !prq_full) begin
                    event_activate = s_req_data[0];
                    event_deactivate = ~s_req_data[0];
                end
            end

            // buffer load response
            else
                buffer_response(status);

        end

        // -- error code --
        // ----------------
        else if (s_req_addr == `PRGA_RXI_NSRID_ERRCODE) begin

            // store is ignored
            if (|s_req_strb)
                buffer_bogus;

            // buffer load response
            else
                buffer_response(errcode);

        end

        // -- clkdiv --
        // ------------
        else if (s_req_addr == `PRGA_RXI_NSRID_CLKDIV) begin

            // store is processed only in the system clock domain
            if (s_req_strb[0]) begin
                buffer_bogus;
                clkdiv_factor_we = s_req_vld && !prq_full;
            end

            // buffer load response
            else
                buffer_response(clkdiv_factor);

        end

        // -- soft register timer --
        // -------------------------
        else if (s_req_addr == `PRGA_RXI_NSRID_SOFTREG_TIMEOUT) begin

            // store needs to be forwarded into the application clock domain
            if (|s_req_strb) begin
                forward_f2b;
                timeout_limit_we = s_req_vld && !f2b_full && !prq_full;
            end

            // buffer load response
            else
                buffer_response(timeout_limit);
        end

        // -- application reset countdown --
        // ---------------------------------
        else if (s_req_addr == `PRGA_RXI_NSRID_APP_RST) begin

            // store needs to be forwarded into the application clock domain
            if (|s_req_strb)
                forward_f2b;

            // buffer bogus response
            else
                buffer_bogus;
        end

        // -- programming reset --
        // -----------------------
        else if (s_req_addr == `PRGA_RXI_NSRID_PROG_RST) begin

            // Notes:
            //
            //  1. programming reset should only be issued when status is
            //     PROGRAMMING, PROG_ERROR, or STANDBY
            //
            // store and load are both processed only in the system clock domain
            // load does nothing and returns bogus data
            buffer_bogus;
            prog_rst_countdown_rst = s_req_vld && !prq_full && |s_req_strb;
        end

        // -- YAMI enable --
        // -----------------
        else if (s_req_addr == `PRGA_RXI_NSRID_ENABLE_YAMI) begin

            // store needs to be forwarded into the application clock domain
            if (|s_req_strb) begin
                forward_f2b;
                yami_enable_we = s_req_vld && !f2b_full && !prq_full;
            end

            // buffer load response
            else
                buffer_response(yami_enable);
        end

        // -- reserved control register space --
        // -------------------------------------
        else if (s_req_addr < `PRGA_RXI_NSRID_SCRATCHPAD) begin
            
            // do nothing and return bogus data
            buffer_bogus;
        end

        // -- scratchpad registers --
        // --------------------------
        else if (s_req_addr < `PRGA_RXI_NSRID_PROG) begin

            if (|s_req_strb) begin
                buffer_bogus;
                if (s_req_vld && !prq_full)
                    scratchpad_strb = s_req_strb;
            end

            // buffer load response
            else
                buffer_response(scratchpads[scratchpad_id]);

        end

        // -- programming registers --
        // ---------------------------
        else if (s_req_addr < `PRGA_RXI_NSRID_HSR) begin

            // send to programming backend
            s_req_rdy = prog_req_rdy && !prq_full;
            prog_req_vld = s_req_vld && !prq_full;
            prq_wr = s_req_vld && prog_req_rdy;
            prq_din = PRQ_TOKEN_PROG;
        end

        // -- hardware-sync'ed registers --
        // --------------------------------
        else if (s_req_addr < `PRGA_RXI_SRID_BASE) begin

            // -- HSR: input FIFO --
            // ---------------------
            if (hsr_id < `PRGA_RXI_HSRID_OQ) begin
                s_req_rdy = !prq_full && (!iq_full[hsr_id[0 +: `PRGA_RXI_HSR_IQ_ID_WIDTH]] || ~&s_req_strb);
                iq_wr[hsr_id[0 +: `PRGA_RXI_HSR_IQ_ID_WIDTH]] = s_req_vld && |s_req_strb && !prq_full;
                prq_wr = s_req_vld && (!iq_full[hsr_id[0 +: `PRGA_RXI_HSR_IQ_ID_WIDTH]] || ~&s_req_strb);
                prq_din = PRQ_TOKEN_BOGUS;
            end

            // -- HSR: output FIFO --
            // ----------------------
            else if (hsr_id < `PRGA_RXI_HSRID_TQ) begin

                // ignore stores
                if (|s_req_strb)
                    buffer_bogus;

                // blocking load, but be aware of errors
                else if (errcode != `PRGA_RXI_ERRCODE_NONE)
                    buffer_response(errcode);

                else if (!oq_empty[oq_id]) begin
                    buffer_response(oq_dout[oq_id]);
                    oq_rd[oq_id] = s_req_vld && !prq_full && !rb_full;
                end
            end

            // -- HSR: output token FIFO (blocking load) --
            // --------------------------------------------
            else if (hsr_id < `PRGA_RXI_HSRID_TQ_NB) begin

                // ignore stores
                if (|s_req_strb)
                    buffer_bogus;

                // block load, but be aware of errors
                else if (errcode != `PRGA_RXI_ERRCODE_NONE)
                    buffer_response(errcode);

                else if (!tq_empty[tq_id]) begin
                    buffer_bogus;
                    tq_rd[tq_id] = s_req_vld && !prq_full;
                end
            end

            // -- HSR: output token FIFO (non-blocking load) --
            // ------------------------------------------------
            else if (hsr_id < `PRGA_RXI_HSRID_PLAIN) begin

                // ignore stores
                if (|s_req_strb)
                    buffer_bogus;

                // non-blocking load!
                else if (errcode != `PRGA_RXI_ERRCODE_NONE)
                    buffer_response(errcode);

                else if (tq_empty[tq_id])
                    buffer_response(`PRGA_RXI_ERRCODE_NOTOKEN);

                else begin
                    buffer_bogus;
                    tq_rd[tq_id] = s_req_vld && !prq_full;
                end
            end

            // -- HSR: plain registers --
            // --------------------------
            else begin
                phsr_vld = s_req_vld && !prq_full;

                // stores always succeed
                if (|s_req_strb)
                    buffer_bogus;

                // buffer load response
                else
                    buffer_response(phsr_dout);

            end
        end

        // -- HSR sync takes priority over custom soft registers --
        // --------------------------------------------------------

        // -- sync plain registers first --
        // --------------------------------
        if (!f2b_wr) begin
            f2b_wr = phsr_f2b_vld;
            f2b_data[`PRGA_RXI_F2B_STRB_INDEX] = { `PRGA_RXI_DATA_BYTES {1'b1} };
            f2b_data[`PRGA_RXI_F2B_REGID_INDEX] = `PRGA_RXI_NSRID_HSR
                                                  + `PRGA_RXI_HSRID_PLAIN
                                                  + phsr_f2b_id;
            f2b_data[`PRGA_RXI_F2B_DATA_INDEX] = phsr_f2b_data;
            phsr_f2b_rdy = !f2b_full;
        end

        // -- sync input FIFO next --
        // --------------------------
        if (!f2b_wr) begin
            f2b_wr = iq_vld;
            f2b_data[`PRGA_RXI_F2B_STRB_INDEX] = { `PRGA_RXI_DATA_BYTES {1'b1} };
            f2b_data[`PRGA_RXI_F2B_REGID_INDEX] = `PRGA_RXI_NSRID_HSR
                                                  + `PRGA_RXI_HSRID_IQ
                                                  + iq_id;
            f2b_data[`PRGA_RXI_F2B_DATA_INDEX] = iq_dout;
            iq_rdy = !f2b_full;
        end

        // -- custom soft registers --
        // ---------------------------
        if (!f2b_wr && s_req_addr >= `PRGA_RXI_SRID_BASE) begin
            // active?
            if (rxi_active)
                forward_f2b;

            // return bogus for inactive interface
            else
                buffer_bogus;
        end

    end

    // =======================================================================
    // -- Response -----------------------------------------------------------
    // =======================================================================

    // -- decode b2f element --
    wire                                    b2f_sync;
    wire [`PRGA_RXI_NSRID_WIDTH-1:0]        b2f_nsr_id;
    wire [`PRGA_RXI_HSRID_WIDTH-1:0]        b2f_hsr_id;
    wire [`PRGA_RXI_HSR_OQ_ID_WIDTH-1:0]    b2f_oq_id;
    wire [`PRGA_RXI_HSR_TQ_ID_WIDTH-1:0]    b2f_tq_id;

    assign b2f_sync = b2f_data[`PRGA_RXI_B2F_SYNC_INDEX];
    assign b2f_nsr_id = b2f_data[`PRGA_RXI_B2F_NSRID_INDEX];
    assign b2f_hsr_id = b2f_nsr_id[0+:`PRGA_RXI_HSRID_WIDTH];
    assign phsr_b2f_id = b2f_nsr_id[0+:`PRGA_RXI_HSR_PLAIN_ID_WIDTH];
    assign b2f_oq_id = b2f_nsr_id[0+:`PRGA_RXI_HSR_OQ_ID_WIDTH];
    assign b2f_tq_id = b2f_nsr_id[0+:`PRGA_RXI_HSR_TQ_ID_WIDTH];

    always @* begin
        s_resp_vld = 1'b0;
        s_resp_data = { `PRGA_RXI_DATA_WIDTH {1'b0} };
        prog_resp_rdy = 1'b0;
        b2f_rd = 1'b0;
        event_app_error = 1'b0;
        oq_wr = { `PRGA_RXI_NUM_HSR_OQS {1'b0} };
        tq_wr = { `PRGA_RXI_NUM_HSR_TQS {1'b0} };
        phsr_b2f_sync = 1'b0;
        prq_rd = 1'b0;
        rb_rd = 1'b0;

        // -- pop pending response queue --
        // --------------------------------
        case (prq_dout)
            PRQ_TOKEN_PROG: begin
                s_resp_vld = !prq_empty && prog_resp_vld && !prog_resp_err;
                s_resp_data = prog_resp_data;
                prog_resp_rdy = (!prq_empty && s_resp_rdy) || prog_resp_err;
                prq_rd = prog_resp_vld && !prog_resp_err && s_resp_rdy;
            end

            PRQ_TOKEN_B2F: if (!b2f_sync) begin
                s_resp_vld = !prq_empty && !b2f_empty;
                s_resp_data = b2f_data[`PRGA_RXI_B2F_DATA_INDEX];
                b2f_rd = !prq_empty && s_resp_rdy;
                prq_rd = !b2f_empty && s_resp_rdy;
            end

            PRQ_TOKEN_BOGUS: begin
                s_resp_vld = !prq_empty;
                prq_rd = s_resp_rdy;
            end

            PRQ_TOKEN_RB: begin
                s_resp_vld = !prq_empty && !rb_empty;
                s_resp_data = rb_dout;
                prq_rd = !rb_empty && s_resp_rdy;
                rb_rd = !prq_empty && s_resp_rdy;
            end
        endcase

        // -- active synchronization --
        // ----------------------------
        if (!b2f_empty && b2f_sync) begin
            b2f_rd = 1'b1;

            // -- app errcode --
            // -----------------
            if (b2f_nsr_id == `PRGA_RXI_NSRID_ERRCODE)
                event_app_error = 1'b1;

            // -- Hardware-sync'ed registers --
            // --------------------------------
            else if (b2f_nsr_id >= `PRGA_RXI_NSRID_HSR) begin

                // -- HSR: output FIFOs --
                // -----------------------
                if (b2f_hsr_id < `PRGA_RXI_HSRID_TQ)
                    oq_wr[b2f_oq_id] = 1'b1;

                // -- HSR: output token FIFOs --
                // -----------------------------
                else if (b2f_hsr_id < `PRGA_RXI_HSRID_PLAIN)
                    tq_wr[b2f_tq_id] = 1'b1;

                // -- HSR: plain registers --
                // --------------------------
                else
                    phsr_b2f_sync = 1'b1;
            end
        end
    end

endmodule
