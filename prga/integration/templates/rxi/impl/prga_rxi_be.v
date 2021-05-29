// Automatically generated by PRGA's RTL generator

/*
* RXI in application clock domain (backend).
*/

`include "prga_rxi.vh"
`default_nettype none

module prga_rxi_be #(
    parameter [`PRGA_RXI_DATA_WIDTH - 1:0]  DEFAULT_TIMEOUT = 1000
) (
    // -- Interface Ctrl -----------------------------------------------------
    input wire                                          clk
    , input wire                                        rst_n
    , input wire [`PRGA_RXI_NUM_YAMI-1:0]               yami_err_i
    , output wire                                       yami_deactivate_o
    , output wire [`PRGA_RXI_NUM_YAMI-1:0]              yami_activate_o

    // -- FE -> BE Async FIFO ------------------------------------------------
    , output reg                                        f2b_rd
    , input wire                                        f2b_empty
    , input wire [`PRGA_RXI_F2B_ELEM_WIDTH-1:0]         f2b_elem

    // -- BE -> FE Async FIFO ------------------------------------------------
    , input wire                                        b2f_full
    , output reg                                        b2f_wr
    , output reg [`PRGA_RXI_B2F_ELEM_WIDTH-1:0]         b2f_elem

    // -- Application Control ------------------------------------------------
    , output reg                                        app_rst_n

    // -- Applictaion Master Interface ---------------------------------------
    , input wire                                        m_req_rdy
    , output reg                                        m_req_vld
    , output wire [`PRGA_RXI_REGID_WIDTH-1:0]           m_req_addr  // register ID instead of address
    , output wire [`PRGA_RXI_DATA_BYTES-1:0]            m_req_strb
    , output wire [`PRGA_RXI_DATA_WIDTH-1:0]            m_req_data

    , output reg                                        m_resp_rdy
    , input wire                                        m_resp_vld
    , input wire                                        m_resp_sync
    , input wire [`PRGA_RXI_HSRID_WIDTH-1:0]            m_resp_syncaddr
    , input wire [`PRGA_RXI_DATA_WIDTH-1:0]             m_resp_data
    , input wire                                        m_resp_parity
    );

    // =======================================================================
    // -- FE -> BE FIFO ------------------------------------------------------
    // =======================================================================

    // -- decode fifo element ------------------------------------------------
    wire [`PRGA_RXI_DATA_BYTES-1:0]     f2b_strb;
    wire [`PRGA_RXI_REGID_WIDTH-1:0]    f2b_regid;
    wire [`PRGA_RXI_DATA_WIDTH-1:0]     f2b_data;

    assign f2b_strb = f2b_elem[`PRGA_RXI_F2B_STRB_INDEX];
    assign f2b_regid = f2b_elem[`PRGA_RXI_F2B_REGID_INDEX];
    assign f2b_data = f2b_elem[`PRGA_RXI_F2B_DATA_INDEX];

    assign m_req_addr = f2b_regid;
    assign m_req_strb = f2b_strb;
    assign m_req_data = f2b_data;

    // =======================================================================
    // -- Ctrl Registers -----------------------------------------------------
    // =======================================================================

    // -- backend status --
    reg [`PRGA_RXI_STATUS_WIDTH-1:0]    status;
    reg                                 event_activate, event_deactivate, event_error;

    always @(posedge clk) begin
        if (~rst_n) begin
            status  <= `PRGA_RXI_STATUS_RESET;
        end else begin
            case (status)
                `PRGA_RXI_STATUS_RESET:
                    status  <= `PRGA_RXI_STATUS_STANDBY;

                `PRGA_RXI_STATUS_STANDBY,
                `PRGA_RXI_STATUS_APP_ERROR:
                    status  <= event_activate ? `PRGA_RXI_STATUS_ACTIVE : status;

                `PRGA_RXI_STATUS_ACTIVE:
                    status  <= event_error ? `PRGA_RXI_STATUS_APP_ERROR :
                               event_deactivate ? `PRGA_RXI_STATUS_STANDBY : status;
            endcase
        end
    end

    wire rxi_active;
    assign rxi_active = status == `PRGA_RXI_STATUS_ACTIVE;
    assign yami_deactivate_o = !rxi_active;

    // -- app reset --
    reg                             app_rst_countdown_rst;
    wire [`PRGA_RXI_DATA_WIDTH-1:0] app_rst_countdown;

    prga_byteaddressable_reg #(
        .NUM_BYTES  (`PRGA_RXI_DATA_BYTES)
    ) i_app_rst (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.wr                (app_rst_countdown_rst || app_rst_countdown > 0)
        ,.mask              (app_rst_countdown_rst ? f2b_strb :
                                                     {`PRGA_RXI_DATA_BYTES {1'b1} })
        ,.din               (app_rst_countdown_rst ? f2b_data :
                                                     (app_rst_countdown - 1))
        ,.dout              (app_rst_countdown)
        );

    always @(posedge clk) begin
        if (~rst_n) begin
            // system reset locks application in reset state until explicitly de-reset
            app_rst_n           <= 1'b0;
        end else if (!rxi_active) begin
            app_rst_n           <= 1'b0;
        end else if (app_rst_countdown_rst) begin
            app_rst_n           <= 1'b0;
        end else if (app_rst_countdown == 1) begin
            // prevent auto-releasing app_rst_n
            app_rst_n           <= 1'b1;
        end
    end

    // -- timeout --
    reg                             timeout_limit_we;
    wire [`PRGA_RXI_DATA_WIDTH-1:0] timeout_limit;

    prga_byteaddressable_reg #(
        .NUM_BYTES  (`PRGA_RXI_DATA_BYTES)
        ,.RST_VALUE (DEFAULT_TIMEOUT)
    ) i_timeout_limit (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.wr                (timeout_limit_we)
        ,.mask              (f2b_strb)
        ,.din               (f2b_data)
        ,.dout              (timeout_limit)
        );

    // -- errcode --
    reg                                 b2f_errcode_unsynced;
    reg [`PRGA_RXI_ERRCODE_WIDTH-1:0]   b2f_errcode_f, b2f_errcode;

    always @(posedge clk) begin
        if (~rst_n) begin
            b2f_errcode_unsynced    <= 1'b0;
            b2f_errcode_f           <= { `PRGA_RXI_ERRCODE_WIDTH {1'b0} };
        end else if (event_error) begin
            b2f_errcode_unsynced    <= b2f_full;
            b2f_errcode_f           <= b2f_errcode;
        end else if (b2f_errcode_unsynced) begin
            b2f_errcode_unsynced    <= !b2f_full;   // errcode sync takes precedence over other b2f traffic
        end else if (event_activate) begin
            b2f_errcode_unsynced    <= 1'b0;
        end
    end

    // -- YAMI enable --
    reg                             yami_enable_we;
    wire [`PRGA_RXI_DATA_WIDTH-1:0] yami_enable;

    prga_byteaddressable_reg #(
        .NUM_BYTES  (`PRGA_RXI_DATA_BYTES)
    ) i_yami_enable (
        .clk                (clk)
        ,.rst               (~rst_n)
        ,.wr                (1'b1)
        ,.mask              (yami_enable_we ? f2b_strb :
                                              {`PRGA_RXI_DATA_BYTES {1'b1} })
        ,.din               (yami_enable_we ? f2b_data :
                                              {`PRGA_RXI_DATA_WIDTH {1'b0} })
        ,.dout              (yami_enable)
        );

    assign yami_activate_o = { `PRGA_RXI_NUM_YAMI {rxi_active} } & yami_enable[0+:`PRGA_RXI_NUM_YAMI];

    // =======================================================================
    // -- Application - RXI Channel ------------------------------------------ 
    // =======================================================================

    // -- parity check -------------------------------------------------------
    wire m_resp_parity_fail;
    assign m_resp_parity_fail = ^{m_resp_sync, m_resp_syncaddr, m_resp_data, m_resp_parity};

    // -- pending response queue ---------------------------------------------
    localparam  PRQ_TOKEN_WIDTH = 1;
    localparam  PRQ_TOKEN_DROP = 1'b0,  // drop the response from the application
                PRQ_TOKEN_FWD = 1'b1;   // forward the response from the application to B2F FIFO

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

    // -- timer --------------------------------------------------------------
    reg                             m_req_timeout, m_resp_timeout;
    reg [`PRGA_RXI_DATA_WIDTH-1:0]  m_req_timer, m_resp_timer;

    always @(posedge clk) begin
        if (~rst_n) begin
            m_req_timeout   <= 1'b0;
            m_resp_timeout  <= 1'b0;
        end else if (!rxi_active) begin
            m_req_timeout   <= 1'b0;
            m_resp_timeout  <= 1'b0;
        end else begin
            m_req_timeout   <= m_req_timeout || m_req_timer == timeout_limit;
            m_resp_timeout  <= m_resp_timeout || m_resp_timer == timeout_limit;
        end
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            m_req_timer     <= { `PRGA_RXI_DATA_WIDTH {1'b0} };
        end else if (!rxi_active || m_req_timeout || m_req_rdy) begin
            m_req_timer     <= { `PRGA_RXI_DATA_WIDTH {1'b0} };
        end else if (m_req_vld) begin
            m_req_timer     <= m_req_timer + 1;
        end
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            m_resp_timer    <= { `PRGA_RXI_DATA_WIDTH {1'b0} };
        end else if (!rxi_active || m_resp_timeout || (m_resp_vld && !m_resp_sync)) begin
            m_resp_timer    <= { `PRGA_RXI_DATA_WIDTH {1'b0} };
        end else if (m_resp_rdy && !prq_empty) begin
            m_resp_timer    <= m_resp_timer + 1;
        end
    end

    // =======================================================================
    // -- RXI - Application Channel ------------------------------------------ 
    // =======================================================================

    reg loopback_vld;   // respond to stores to control registers

    always @* begin
        f2b_rd = 1'b0;
        m_req_vld = 1'b0;

        event_activate = 1'b0;
        event_deactivate = 1'b0;
        app_rst_countdown_rst = 1'b0;
        timeout_limit_we = 1'b0;
        yami_enable_we = 1'b0;

        prq_din = PRQ_TOKEN_FWD;
        prq_wr = 1'b0;
        loopback_vld = 1'b0;

        // unsynchronized error code
        if (b2f_errcode_unsynced) begin
            // sit and wait!
        end

        // hardware-sync'ed or custom soft registers
        else if (f2b_regid >= `PRGA_RXI_NSRID_HSR) begin
            
            prq_wr = !f2b_empty;
            prq_din = (f2b_regid < `PRGA_RXI_SRID_BASE) ? PRQ_TOKEN_DROP : PRQ_TOKEN_FWD;

            // inactive interface
            if (!rxi_active || event_error) begin
                // push to PRQ, but not actually send the request
                // only process it if we have space in the pending response queue
                f2b_rd = ~prq_full;
                prq_wr = !f2b_empty;
            end

            // active interface
            else begin
                // send the request
                f2b_rd = m_req_rdy && ~prq_full;
                m_req_vld = !f2b_empty && ~prq_full;
                prq_wr = m_req_rdy && !f2b_empty;
            end
        end
        
        // control registers: take a peek and maybe process it, but only respond
        // when there are no pending responses left
        //
        // strb are assumed to be all ones
        else begin
            f2b_rd = prq_empty && !b2f_full;
            loopback_vld = prq_empty && !f2b_empty;

            case (f2b_regid)
                // process status change as soon as we see this request
                `PRGA_RXI_NSRID_STATUS: begin
                    event_activate = !f2b_empty && f2b_data[0];
                    event_deactivate = !f2b_empty && ~f2b_data[0];
                end

                // wait until no pending responses left before we trigger app
                // reset
                `PRGA_RXI_NSRID_APP_RST:
                    app_rst_countdown_rst = prq_empty && !f2b_empty;

                // update soft register timeout limit as soon as we see this
                // request
                `PRGA_RXI_NSRID_SOFTREG_TIMEOUT:
                    timeout_limit_we = !f2b_empty;

                // update YAMI enable state as soon as we see this
                `PRGA_RXI_NSRID_ENABLE_YAMI:
                    yami_enable_we = !f2b_empty;

            endcase
        end
    end

    // =======================================================================
    // -- BE -> FE FIFO ------------------------------------------------------
    // =======================================================================

    /* Notes
    *
    *   BE -> FE FIFO has three types of traffic:
    *
    *     - Top priority: synchronization of the control registers (error)
    *     - Then: ack to stores to the control registers
    *     - Then: response/synchronization from the application
    *
    */

    task automatic sync_errcode;
        input [`PRGA_RXI_ERRCODE_WIDTH-1:0] errcode;
        begin
            b2f_wr = 1'b1;
            b2f_elem[`PRGA_RXI_B2F_SYNC_INDEX] = 1'b1;
            b2f_elem[`PRGA_RXI_B2F_NSRID_INDEX] = `PRGA_RXI_NSRID_ERRCODE;
            b2f_elem[`PRGA_RXI_B2F_DATA_BASE+:`PRGA_RXI_ERRCODE_WIDTH] = errcode;
            b2f_errcode = errcode;
        end
    endtask

    always @* begin
        b2f_wr = 1'b0;
        b2f_elem = { `PRGA_RXI_B2F_ELEM_WIDTH {1'b0} };
        m_resp_rdy = 1'b0;
        event_error = 1'b0;
        prq_rd = 1'b0;
        b2f_errcode = b2f_errcode_f;

        // unsynchronized error code
        if (b2f_errcode_unsynced) begin
            sync_errcode(b2f_errcode_f);
        end
        
        // control register accesses
        else if (loopback_vld) begin
            b2f_wr = 1'b1;
            b2f_elem[`PRGA_RXI_B2F_SYNC_INDEX] = 1'b0;
            // register ID and data are irrelevant
            // (because only stores to control registers are forwarded into the
            // application clock domain)
        end
        
        // active request
        else if (rxi_active) begin
            // YAMI error?
            if (|yami_err_i) begin
                event_error = 1'b1;
                sync_errcode(`PRGA_RXI_ERRCODE_YAMI + yami_err_i);
            end

            // request timeout?
            else if (m_req_timeout) begin
                event_error = 1'b1;
                sync_errcode(`PRGA_RXI_ERRCODE_REQ_TIMEOUT);
            end

            // response timeout?
            else if (m_resp_timeout) begin
                event_error = 1'b1;
                sync_errcode(`PRGA_RXI_ERRCODE_RESP_TIMEOUT);
            end

            // try accepting response
            else begin
                m_resp_rdy = !b2f_full || prq_empty || prq_dout == PRQ_TOKEN_DROP;

                // valid response (or sync)?
                if (m_resp_vld) begin

                    // parity fail?
                    if (m_resp_parity_fail) begin
                        event_error = 1'b1;
                        sync_errcode(`PRGA_RXI_ERRCODE_RESP_PARITY);
                    end

                    // sync?
                    else if (m_resp_sync) begin
                        b2f_wr = 1'b1;
                        b2f_elem[`PRGA_RXI_B2F_SYNC_INDEX] = 1'b1;
                        b2f_elem[`PRGA_RXI_B2F_NSRID_INDEX] = `PRGA_RXI_NSRID_HSR + m_resp_syncaddr;
                        b2f_elem[`PRGA_RXI_B2F_DATA_INDEX] = m_resp_data;
                    end

                    // is there a pending response?
                    else if (prq_empty) begin
                        event_error = 1'b1;
                        sync_errcode(`PRGA_RXI_ERRCODE_RESP_NOREQ);
                    end

                    // do we need to forward this response?
                    else if (prq_dout == PRQ_TOKEN_DROP) begin
                        prq_rd = 1'b1;
                    end

                    // forward response to B2F
                    else begin
                        b2f_wr = 1'b1;
                        b2f_elem[`PRGA_RXI_B2F_SYNC_INDEX] = 1'b0;
                        b2f_elem[`PRGA_RXI_B2F_DATA_INDEX] = m_resp_data;
                        prq_rd = !b2f_full;
                    end
                end
            end
        end

        // not active, but there are pending responses
        else if (!prq_empty) begin
            prq_rd = prq_dout == PRQ_TOKEN_DROP || !b2f_full;
            b2f_wr = prq_dout == PRQ_TOKEN_FWD;
            b2f_elem[`PRGA_RXI_B2F_SYNC_INDEX] = 1'b0;
            // return bogus data
        end
    end

endmodule
