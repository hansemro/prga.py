// Automatically generated by PRGA's RTL generator
`timescale 1ns/1ps

/*
* Memory Protection Layer in fabric clock domain.
*/

`include "prga_utils.vh"
`include "prga_yami.vh"
`default_nettype none

module prga_yami_mprot_fbrc #(
    parameter   DEFAULT_FEATURES    = `PRGA_YAMI_CREG_FEATURE_LOAD | `PRGA_YAMI_CREG_FEATURE_STORE
    , parameter DEFAULT_TIMEOUT     = 32'd1000
) (
    // -- Interface Ctrl -----------------------------------------------------
    input wire                                          clk
    , input wire                                        rst_n
    , output wire                                       err_o       // error signal out
    , input wire                                        shutdown_i  // quick shutdown

    // -- FIFO ---------------------------------------------------------------
    , input wire                                        fifo_fmc_full
    , output reg                                        fifo_fmc_wr
    , output reg [`PRGA_YAMI_FMC_FIFO_DATA_WIDTH-1:0]   fifo_fmc_data

    , output reg                                        fifo_mfc_rd
    , input wire                                        fifo_mfc_empty
    , input wire [`PRGA_YAMI_MFC_FIFO_DATA_WIDTH-1:0]   fifo_mfc_data

    // -- FMC/R (fabric-memory request channel) ------------------------------
    , output reg                                        fmr_rdy
    , input wire                                        fmr_vld
    , input wire [`PRGA_YAMI_FMC_REQTYPE_WIDTH-1:0]     fmr_type
    , input wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]        fmr_addr
    , input wire [`PRGA_YAMI_THREAD_WIDTH-1:0]          fmr_thread
    , input wire [`PRGA_YAMI_SIZE_WIDTH-1:0]            fmr_size
    , input wire [`PRGA_YAMI_LEN_WIDTH-1:0]             fmr_len
    , input wire                                        fmr_parity

    // -- FMC/D (fabric-memory data channel) ---------------------------------
    , output reg                                        fmd_rdy
    , input wire                                        fmd_vld
    , input wire [`PRGA_YAMI_FMC_DATA_WIDTH-1:0]        fmd_data
    , input wire                                        fmd_parity

    // -- MFC/R (memory-fabric response channel) -----------------------------
    , input wire                                        mfr_rdy
    , output reg                                        mfr_vld
    , output reg [`PRGA_YAMI_MFC_RESPTYPE_WIDTH-1:0]    mfr_type
    , output reg [`PRGA_YAMI_THREAD_WIDTH-1:0]          mfr_thread
    , output reg [`PRGA_YAMI_MFC_ADDR_WIDTH-1:0]        mfr_addr

    // -- MFC/D (memory-fabric data channel) ---------------------------------
    , input wire                                        mfd_rdy
    , output reg                                        mfd_vld
    , output reg [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]        mfd_data
    );

    // =======================================================================
    // == Core Status ========================================================
    // =======================================================================
    reg [`PRGA_YAMI_CREG_STATUS_WIDTH-1:0]  status;
    wire                                    creg_activate, creg_deactivate;
    reg                                     event_error;

    always @(posedge clk) begin
        if (~rst_n)
            status          <= `PRGA_YAMI_CREG_STATUS_RESET

        else 
            case (status)
                `PRGA_YAMI_CREG_STATUS_RESET:
                    status  <= `PRGA_YAMI_CREG_STATUS_INACTIVE;

                `PRGA_YAMI_CREG_STATUS_INACTIVE,
                `PRGA_YAMI_CREG_STATUS_ERROR:
                    status  <= creg_activate ? `PRGA_YAMI_CREG_STATUS_ACTIVE : status;

                `PRGA_YAMI_CREG_STATUS_ACTIVE:
                    status  <= event_error ? `PRGA_YAMI_CREG_STATUS_ERROR :
                               creg_deactivate || shutdown_i ? `PRGA_YAMI_CREG_STATUS_INACTIVE : status;
            endcase
    end

    wire yami_active;
    assign yami_active = status == `PRGA_YAMI_CREG_STATUS_ACTIVE;
    assign err_o = status == `PRGA_YAMI_CREG_STATUS_ERROR;

    // =======================================================================
    // == Ctrl Registers =====================================================
    // =======================================================================
    reg                                     creg_we;
    wire [`PRGA_YAMI_CREG_ADDR_WIDTH-1:0]   creg_addr;
    wire [`PRGA_YAMI_CREG_DATA_WIDTH-1:0]   creg_data;

    assign creg_addr = fifo_mfc_data[`PRGA_YAMI_MFC_FIFO_HDR_CREG_ADDR_INDEX];
    assign creg_data = fifo_mfc_data[`PRGA_YAMI_MFC_FIFO_HDR_CREG_DATA_INDEX];

    // -- status --
    assign creg_activate   = creg_we && creg_addr == `PRGA_YAMI_CREG_ADDR_STATUS && |creg_data;
    assign creg_deactivate = creg_we && creg_addr == `PRGA_YAMI_CREG_ADDR_STATUS && ~|creg_data;

    // -- features --
    reg [`PRGA_YAMI_CREG_FEATURE_WIDTH-1:0] creg_features;
    always @(posedge clk) begin
        if (~rst_n)
            creg_features   <= DEFAULT_FEATURES;
        else if (creg_we && creg_addr == `PRGA_YAMI_CREG_ADDR_FEATURES)
            creg_features   <= creg_data[0 +: `PRGA_YAMI_CREG_FEATURE_WIDTH];
    end

    // -- timeout --
    reg [`PRGA_YAMI_CREG_DATA_WIDTH-1:0]    creg_timeout;
    always @(posedge clk) begin
        if (~rst_n)
            creg_timeout    <= DEFAULT_TIMEOUT;
        else if (creg_we && creg_addr == `PRGA_YAMI_CREG_ADDR_TIMEOUT)
            creg_timeout    <= creg_data;
    end

    // -- error message --
    reg [`PRGA_YAMI_CREG_DATA_WIDTH-1:0]    creg_errcode, creg_errcode_next;
    always @(posedge clk) begin
        if (~rst_n)
            creg_errcode    <= { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };
        else if (event_error)
            creg_errcode    <= creg_errcode_next;
        else if (creg_activate)
            creg_errcode    <= { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };
    end

    // =======================================================================
    // == MFC channel ========================================================
    // =======================================================================

    // -- MFC/D buffer -------------------------------------------------------
    // assemble multi-FIFO-element data
    localparam  MFC_FIFO_ELEM_OFFSET_WIDTH = `PRGA_MAX2( 0, `PRGA_YAMI_MFC_DATA_BYTES_LOG2 - `PRGA_YAMI_MFC_FIFO_DATA_BYTES_LOG2 );

    reg                                     mfd_data_vld_elem;
    wire                                    mfd_data_last_elem;

    generate
        if (MFC_FIFO_ELEM_OFFSET_WIDTH == 0) begin
            assign mfd_data = fifo_mfc_data[0 +: `PRGA_YAMI_MFC_DATA_WIDTH];
            assign mfd_data_last_elem = 1'b1;

        end else begin
            reg [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]     mfd_data_f;
            reg [MFC_FIFO_ELEM_OFFSET_WIDTH-1:0]    mfd_data_elem_offset;

            // buffer data
            always @(posedge clk) begin
                if (~rst_n) begin
                    mfd_data_f              <= { `PRGA_YAMI_MFC_DATA_WIDTH {1'b0} };
                    mfd_data_elem_offset    <= { MFC_FIFO_ELEM_OFFSET_WIDTH {1'b0} };
                end else begin
                    mfd_data_f              <= mfd_data;
                    mfd_data_elem_offset    <= mfd_data_vld_elem ? (mfd_data_elem_offset + 1) : mfd_data_elem_offset;
                end
            end

            integer gv_mfd_data;
            for (gv_mfd_data = 0; gv_mfd_data < (1 << MFC_FIFO_ELEM_OFFSET_WIDTH;) gv_mfd_data = gv_mfd_data + 1) begin: g_mfd_data
                wire [`PRGA_YAMI_MFC_FIFO_DATA_WIDTH-1:0]   mfd_data_tmp;

                assign mfd_data_tmp = mfd_data_vld_elem && mfd_data_elem_offset == gv_mfd_data
                                      ? fifo_mfc_data
                                      : mfd_data_f[gv_mfd_data * `PRGA_YAMI_MFC_FIFO_DATA_WIDTH +: `PRGA_YAMI_MFC_FIFO_DATA_WIDTH];
                assign mfd_data[gv_mfd_data * `PRGA_YAMI_MFC_FIFO_DATA_WIDTH +: `PRGA_YAMI_MFC_FIFO_DATA_WIDTH] = mfd_data_tmp;
            end

            assign mfd_data_last_elem = &mfd_data_elem_offset;

        end
    endgenerate

    // -- MFC Timers ---------------------------------------------------------
    reg                                         mfr_timeout, mfd_timeout;
    reg [`PRGA_YAMI_CREG_DATA_WIDTH-1:0]        mfr_timer, mfd_timer;

    always @(posedge clk) begin
        if (~rst_n) begin
            mfr_timeout <= 1'b0;
            mfd_timeout <= 1'b0;
        end else if (!yami_active) begin
            mfr_timeout <= 1'b0;
            mfd_timeout <= 1'b0;
        end else begin
            mfr_timeout <= mfr_timeout || mfr_timer == creg_timeout;
            mfd_timeout <= mfd_timeout || mfd_timer == creg_timeout;
        end
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            mfr_timer   <= { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };
        end else if (!yami_active) begin
            mfr_timer   <= { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };
        end else if (mfr_vld) begin
            mfr_timer   <= mfr_timer + 1;
        end
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            mfd_timer   <= { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };
        end else if (!yami_active) begin
            mfd_timer   <= { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };
        end else if (mfd_vld) begin
            mfd_timer   <= mfd_timer + 1;
        end
    end

    // -- Core Logic ---------------------------------------------------------
    localparam  MFC_STATE_RESET     = 2'd0,
                MFC_STATE_HDR       = 2'd1,
                MFC_STATE_PLD       = 2'd2,
                MFC_STATE_DRAIN     = 2'd3;

    reg [1:0]                                   mfc_state, mfc_state_next;
    reg [`PRGA_YAMI_LEN_WIDTH-1:0]              mfc_payload, mfc_payload_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            mfc_state       <= MFC_STATE_RESET;
            mfc_payload     <= { `PRGA_YAMI_MFC_FIFO_HDR_PAYLOAD_WIDTH {1'b0} };
        end else begin
            mfc_state       <= mfc_state_next;
            mfc_payload     <= mfc_payload_next;
        end
    end

    // decode FIFO header
    wire [`PRGA_YAMI_LEN_WIDTH-1:0]             mfc_hdr_len;

    assign mfr_type = fifo_mfc_data[`PRGA_YAMI_MFC_FIFO_HDR_RESPTYPE_INDEX];
    assign mfr_thread = fifo_mfc_data[`PRGA_YAMI_MFC_FIFO_HDR_THREAD_INDEX];
    assign mfr_addr = fifo_mfc_data[`PRGA_YAMI_MFC_FIFO_HDR_ADDR_INDEX];
    assign mfc_hdr_len = fifo_mfc_data[`PRGA_YAMI_MFC_FIFO_HDR_LEN_INDEX];

    // FSM task: process MFC FIFO header with data payload
    task automatic process_mfc_hdr_with_data;
        input feature;
        begin
            if ( !(yami_active && feature) ) begin
                // drain FIFO when the interface is inactive, or the interface
                // is configured without the required feature
                fifo_mfc_rd = 1'b1;

                // if there are payloads, drain them
                if (!fifo_mfc_empty) begin
                    mfc_state_next = MFC_STATE_DRAIN;
                    mfc_payload_next = mfc_hdr_len;
                end

            end else begin
                // only read FIFO when the buffer is ready
                fifo_mfc_rd = mfr_rdy;
                mfr_vld = !fifo_mfc_empty;

                if (mfr_rdy && !fifo_mfc_empty) begin
                    mfc_state_next = MFC_STATE_PLD;
                    mfc_payload_next = mfc_hdr_len;
                end
            end
        end
    endtask

    // FSM task: process MFC FIFO header without data payload
    task automatic process_mfc_hdr_without_data;
        input feature;
        begin
            if ( !(yami_active && feature) ) begin
                // drain FIFO when the interface is inactive, or the interface
                // is configured without the required feature
                fifo_mfc_rd = 1'b1;

            end else begin
                // only read FIFO when the buffer is ready
                fifo_mfc_rd = mfr_rdy;
                mfr_vld = !fifo_mfc_empty;

            end
        end
    endtask

    // FSM task: accept data element from MFC fifo
    task automatic process_mfc_data;
        input rd;
        begin
            fifo_mfc_rd = rd;
            mfd_data_vld_elem = !fifo_mfc_empty;

            if (mfd_data_last_elem && rd && !fifo_mfc_empty) begin
                if (mfc_payload)
                    mfc_payload_next = mfc_payload - 1;
                else
                    // last element
                    mfc_state_next = MFC_STATE_HDR;
            end
        end
    endtask

    // FMC message caused by FMC CREG_LOAD/CREG_STORE
    reg                                     fmc_creg_vld, fmc_creg_ack;
    reg [`PRGA_YAMI_CREG_DATA_WIDTH-1:0]    fmc_creg_data;

    // Main state machine
    always @* begin
        fifo_mfc_rd = 1'b0;
        creg_we = 1'b0;

        mfr_vld = 1'b0;
        mfd_vld = 1'b0;
        mfd_data_vld_elem = 1'b0;

        mfc_state_next = mfc_state;
        mfc_payload_next = mfc_payload;

        fmc_creg_vld = 1'b0;
        fmc_creg_data = { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };

        case (mfc_state)
            MFC_STATE_RESET:
                mfc_state_next = MFC_STATE_HDR;

            MFC_STATE_HDR: begin
                case (mfr_type)
                    `PRGA_YAMI_MFC_RESPTYPE_CREG_LOAD,
                    `PRGA_YAMI_MFC_RESPTYPE_CREG_STORE: begin
                        fifo_mfc_rd = fmc_creg_ack;
                        creg_we = mfr_type == `PRGA_YAMI_MFC_RESPTYPE_CREG_STORE && fmc_creg_ack;
                        fmc_creg_vld = 1'b1;

                        case (creg_addr)
                            `PRGA_YAMI_CREG_ADDR_STATUS:
                                fmc_creg_data[0 +: `PRGA_YAMI_CREG_STATUS_WIDTH] = status;

                            `PRGA_YAMI_CREG_ADDR_FEATURES:
                                fmc_creg_data[0 +: `PRGA_YAMI_CREG_FEATURE_WIDTH] = creg_features;

                            `PRGA_YAMI_CREG_ADDR_TIMEOUT:
                                fmc_creg_data = creg_timeout;

                            `PRGA_YAMI_CREG_ADDR_ERRCODE:
                                fmc_creg_data = creg_errcode;
                        endcase
                    end

                    `PRGA_YAMI_MFC_RESPTYPE_LOAD_ACK:
                        process_mfc_hdr_with_data(
                            creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_LOAD]
                            );

                    `PRGA_YAMI_MFC_RESPTYPE_AMO_DATA:
                        process_mfc_hdr_with_data(
                            creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_LOAD]
                            && creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_STORE]
                            && creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_NC]
                            && creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_AMO]
                            );

                    `PRGA_YAMI_MFC_RESPTYPE_STORE_ACK:
                        process_mfc_hdr_without_data(
                            creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_STORE]
                            );

                    `PRGA_YAMI_MFC_RESPTYPE_CACHE_INV:
                        process_mfc_hdr_without_data(
                            creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_LOAD]
                            && creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_L1CACHE]
                            );

                    `PRGA_YAMI_MFC_RESPTYPE_AMO_ACK:
                        process_mfc_hdr_without_data(
                            creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_LOAD]
                            && creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_STORE]
                            && creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_NC]
                            && creg_features[`PRGA_YAMI_CREG_FEATURE_BIT_AMO]
                            );

                endcase
            end

            MFC_STATE_DRAIN: begin
                // always read FIFO in this case
                process_mfc_data(1'b1);
            end

            MFC_STATE_PLD: begin
                // assemble mfd_data if multiple FIFO elements are needed per
                // mfd_data
                process_mfc_data(!mfd_data_last_elem || mfd_rdy || !yami_active);
                mfd_vld = mfd_data_last_elem && !fifo_mfc_empty && yami_active;
            end
        endcase
    end

    // =======================================================================
    // == FMC channel ========================================================
    // =======================================================================

    // -- FMC Timers ---------------------------------------------------------
    //  FMC/R -> FMC/D latency
    reg                                         fmd_timeout;
    reg [`PRGA_YAMI_CREG_DATA_WIDTH-1:0]        fmd_timer;

    always @(posedge clk) begin
        if (~rst_n) begin
            fmd_timeout <= 1'b0;
        end else if (!yami_active) begin
            fmd_timeout <= 1'b0;
        end else begin
            fmd_timeout <= fmd_timeout || fmd_timer == creg_timeout;
        end
    end

    always @(posedge clk) begin
        if (~rst_n) begin
            fmd_timer <= { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };
        end else if (!yami_active || fmd_timeout || fmd_vld) begin
            fmd_timer <= { `PRGA_YAMI_CREG_DATA_WIDTH {1'b0} };
        end else if (fmd_rdy) begin
            fmd_timer <= fmd_timer + 1;
        end
    end

    // -- FMC Parities -------------------------------------------------------
    wire                                        fmr_parity_fail, fmd_parity_fail;
    assign fmr_parity_fail = ^{fmr_type, fmr_addr, fmr_thread, fmr_size, fmr_len, fmr_parity};
    assign fmd_parity_fail = ^{fmd_data,                                          fmd_parity};

    // -- FMR required features ----------------------------------------------
    reg [`PRGA_YAMI_CREG_FEATURE_WIDTH-1:0]     missing_features;

    always @* begin
        missing_features = { `PRGA_YAMI_CREG_FEATURE_WIDTH {1'b0} };

        // calculate required features first
        case (fmr_type)
            `PRGA_YAMI_FMC_REQTYPE_LOAD:
                missing_features = missing_features
                                    | `PRGA_YAMI_CREG_FEATURE_LOAD;

            `PRGA_YAMI_FMC_REQTYPE_LOAD_NC:
                missing_features = missing_features
                                    | `PRGA_YAMI_CREG_FEATURE_LOAD
                                    | `PRGA_YAMI_CREG_FEATURE_NC;

            `PRGA_YAMI_FMC_REQTYPE_LOAD_REP_NC:
                missing_features = missing_features
                                    | `PRGA_YAMI_CREG_FEATURE_LOAD
                                    | `PRGA_YAMI_CREG_FEATURE_STRREP
                                    | `PRGA_YAMI_CREG_FEATURE_NC;

            `PRGA_YAMI_FMC_REQTYPE_STORE:
                missing_features = missing_features
                                    | `PRGA_YAMI_CREG_FEATURE_STORE;

            `PRGA_YAMI_FMC_REQTYPE_STORE_NC:
                missing_features = missing_features
                                    | `PRGA_YAMI_CREG_FEATURE_STORE
                                    | `PRGA_YAMI_CREG_FEATURE_NC;

            `PRGA_YAMI_FMC_REQTYPE_STORE_REP_NC:
                missing_features = missing_features
                                    | `PRGA_YAMI_CREG_FEATURE_STORE
                                    | `PRGA_YAMI_CREG_FEATURE_STRREP
                                    | `PRGA_YAMI_CREG_FEATURE_NC;

            `PRGA_YAMI_FMC_REQTYPE_AMO_LR,
            `PRGA_YAMI_FMC_REQTYPE_AMO_SC,
            `PRGA_YAMI_FMC_REQTYPE_AMO_SWAP,
            `PRGA_YAMI_FMC_REQTYPE_AMO_ADD,
            `PRGA_YAMI_FMC_REQTYPE_AMO_AND,
            `PRGA_YAMI_FMC_REQTYPE_AMO_OR,
            `PRGA_YAMI_FMC_REQTYPE_AMO_XOR,
            `PRGA_YAMI_FMC_REQTYPE_AMO_MAX,
            `PRGA_YAMI_FMC_REQTYPE_AMO_MAXU,
            `PRGA_YAMI_FMC_REQTYPE_AMO_MIN,
            `PRGA_YAMI_FMC_REQTYPE_AMO_MINU,
            `PRGA_YAMI_FMC_REQTYPE_AMO_CAS1,
            `PRGA_YAMI_FMC_REQTYPE_AMO_CAS2:
                missing_features = missing_features
                                    | `PRGA_YAMI_CREG_FEATURE_LOAD
                                    | `PRGA_YAMI_CREG_FEATURE_STORE
                                    | `PRGA_YAMI_CREG_FEATURE_NC
                                    | `PRGA_YAMI_CREG_FEATURE_AMO;
        endcase

        if (fmr_size != `PRGA_YAMI_SIZE_FULL)
            missing_features = missing_features | `PRGA_YAMI_CREG_FEATURE_SUBWORD;

        if (fmr_thread > 0)
            missing_features = missing_features | `PRGA_YAMI_CREG_FEATURE_THREAD;

        // check which required features are missing
        missing_features = missing_features & ~creg_features;
    end

    // -- Main state machine -------------------------------------------------
    localparam  FMC_STATE_RESET         = 2'd0,
                FMC_STATE_IDLE          = 2'd1,
                FMC_STATE_PLD           = 2'd2;

    reg [1:0]                                   fmc_state, fmc_state_next;
    reg [`PRGA_YAMI_LEN_WIDTH-1:0]              fmc_payload, fmc_payload_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            fmc_state <= FMC_STATE_RESET;
            fmc_payload <= { `PRGA_YAMI_LEN_WIDTH {1'b0} };
        end else begin
            fmc_state <= fmc_state_next;
            fmc_payload <= fmc_payload_next;
        end
    end

    localparam  FMC_DATA_PER_FIFO_ELEM = `PRGA_YAMI_FMC_FIFO_DATA_BYTES / `PRGA_YAMI_FMC_DATA_BYTES;

    localparam  STORE_SIZE_FULL = `PRGA_YAMI_FMC_DATA_BYTES_LOG2 == 0 ? `PRGA_YAMI_SIZE_1B :
                                  `PRGA_YAMI_FMC_DATA_BYTES_LOG2 == 1 ? `PRGA_YAMI_SIZE_2B :
                                  `PRGA_YAMI_FMC_DATA_BYTES_LOG2 == 2 ? `PRGA_YAMI_SIZE_4B :
                                  `PRGA_YAMI_FMC_DATA_BYTES_LOG2 == 3 ? `PRGA_YAMI_SIZE_8B :
                                  `PRGA_YAMI_FMC_DATA_BYTES_LOG2 == 4 ? `PRGA_YAMI_SIZE_16B :
                                  `PRGA_YAMI_FMC_DATA_BYTES_LOG2 == 5 ? `PRGA_YAMI_SIZE_32B :
                                  `PRGA_YAMI_FMC_DATA_BYTES_LOG2 == 6 ? `PRGA_YAMI_SIZE_64B :
                                                                        `PRGA_YAMI_SIZE_FULL;

    localparam  LOAD_SIZE_FULL  = `PRGA_YAMI_MFC_DATA_BYTES_LOG2 == 0 ? `PRGA_YAMI_SIZE_1B :
                                  `PRGA_YAMI_MFC_DATA_BYTES_LOG2 == 1 ? `PRGA_YAMI_SIZE_2B :
                                  `PRGA_YAMI_MFC_DATA_BYTES_LOG2 == 2 ? `PRGA_YAMI_SIZE_4B :
                                  `PRGA_YAMI_MFC_DATA_BYTES_LOG2 == 3 ? `PRGA_YAMI_SIZE_8B :
                                  `PRGA_YAMI_MFC_DATA_BYTES_LOG2 == 4 ? `PRGA_YAMI_SIZE_16B :
                                  `PRGA_YAMI_MFC_DATA_BYTES_LOG2 == 5 ? `PRGA_YAMI_SIZE_32B :
                                  `PRGA_YAMI_MFC_DATA_BYTES_LOG2 == 6 ? `PRGA_YAMI_SIZE_64B :
                                                                        `PRGA_YAMI_SIZE_FULL;

    localparam  AMO_SIZE_FULL   = `PRGA_MIN2(STORE_SIZE_FULL, LOAD_SIZE_FULL);

    always @* begin
        fifo_fmc_wr = 1'b0;
        fifo_fmc_data = { `PRGA_YAMI_FMC_FIFO_DATA_WIDTH {1'b0} };

        creg_errcode_next = { `PRGA_YAMI_FMC_FIFO_DATA_WIDTH {1'b0} };
        event_error = 1'b0;
        fmc_creg_ack = 1'b0;

        fmr_rdy = 1'b0;
        fmd_rdy = 1'b0;

        fmc_state_next = fmc_state;
        fmc_payload_next = fmc_payload;

        case (fmc_state)
            FMC_STATE_RESET:
                fmc_state_next = FMC_STATE_IDLE;

            FMC_STATE_IDLE: if (fmc_creg_vld) begin
                fifo_fmc_wr = 1'b1;
                fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_REQTYPE_INDEX] = `PRGA_YAMI_FMC_REQTYPE_CREG_ACK;
                fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_CREG_DATA_INDEX] = fmc_creg_data;

                fmc_creg_ack = !fifo_fmc_full;
            end else if (yami_active) begin
                if (mfr_timeout) begin
                    creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_MFR_TIMEOUT;
                    event_error = 1'b1;
                end else if (mfd_timeout) begin
                    creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_MFD_TIMEOUT;
                    event_error = 1'b1;
                end else if (fmd_timeout) begin
                    creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_FMD_TIMEOUT;
                    event_error = 1'b1;
                end else if (fmr_vld) begin
                    if (fmr_parity_fail) begin
                        creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_PARITY;
                        event_error = 1'b1;
                    end else if (missing_features) begin
                        creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_MISSING_FEATURES + missing_features;
                        event_error = 1'b1;
                    end else begin
                        case (fmr_type)
                            `PRGA_YAMI_FMC_REQTYPE_LOAD,
                            `PRGA_YAMI_FMC_REQTYPE_LOAD_NC,
                            `PRGA_YAMI_FMC_REQTYPE_LOAD_REP_NC: if (fmr_size > LOAD_SIZE_FULL) begin
                                creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_SIZE_OUT_OF_RANGE;
                                event_error = 1'b1;
                            end else begin
                                fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_SIZE_INDEX] = fmr_size == `PRGA_YAMI_SIZE_FULL
                                                                                    ? LOAD_SIZE_FULL : fmr_size;
                            end

                            `PRGA_YAMI_FMC_REQTYPE_STORE,
                            `PRGA_YAMI_FMC_REQTYPE_STORE_NC,
                            `PRGA_YAMI_FMC_REQTYPE_STORE_REP_NC: if (fmr_size > STORE_SIZE_FULL) begin
                                creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_SIZE_OUT_OF_RANGE;
                                event_error = 1'b1;
                            end else begin
                                fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_SIZE_INDEX] = fmr_size == `PRGA_YAMI_SIZE_FULL
                                                                                    ? STORE_SIZE_FULL : fmr_size;
                                fmc_state_next = FMC_STATE_PLD;
                                fmc_payload_next = fmr_len;
                            end

                            `PRGA_YAMI_FMC_REQTYPE_AMO_LR: if (fmr_size > AMO_SIZE_FULL) begin
                                creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_SIZE_OUT_OF_RANGE;
                                event_error = 1'b1;
                            end else if (|fmr_len) begin
                                creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_NONZERO_LEN + fmr_type;
                                event_error = 1'b1;
                            end else begin
                                fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_SIZE_INDEX] = fmr_size == `PRGA_YAMI_SIZE_FULL
                                                                                    ? AMO_SIZE_FULL : fmr_size;
                            end

                            `PRGA_YAMI_FMC_REQTYPE_AMO_SC,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_SWAP,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_ADD,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_AND,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_OR,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_XOR,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_MAX,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_MAXU,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_MIN,
                            `PRGA_YAMI_FMC_REQTYPE_AMO_MINU: if (fmr_size > AMO_SIZE_FULL) begin
                                creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_SIZE_OUT_OF_RANGE;
                                event_error = 1'b1;
                            end else if (|fmr_len) begin
                                creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_NONZERO_LEN + fmr_type;
                                event_error = 1'b1;
                            end else begin
                                fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_SIZE_INDEX] = fmr_size == `PRGA_YAMI_SIZE_FULL
                                                                                    ? AMO_SIZE_FULL : fmr_size;
                                fmc_state_next = FMC_STATE_PLD;
                                fmc_payload_next = fmr_len;
                            end

                            default: begin
                                creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_INVAL_REQTYPE + fmr_type;
                                event_error = 1'b1;
                            end
                        endcase

                        if (!event_error) begin
                            fifo_fmc_wr = 1'b1;
                            fmr_rdy = !fifo_fmc_full;
                            fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_REQTYPE_INDEX]    = fmr_type;
                            fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_LEN_INDEX]        = fmr_len;
                            fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_THREAD_INDEX]     = fmr_thread;
                            fifo_fmc_data[`PRGA_YAMI_FMC_FIFO_HDR_ADDR_INDEX]       = fmr_addr;
                        end
                    end
                end
            end

            FMC_STATE_PLD: begin
                if (yami_active) begin
                    fmd_rdy = !fifo_fmc_full;

                    if (mfr_timeout) begin
                        fifo_fmc_wr = 1'b1;
                        event_error = 1'b1;
                        creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_MFR_TIMEOUT;
                    end end else if (mfd_timeout) begin
                        fifo_fmc_wr = 1'b1;
                        event_error = 1'b1;
                        creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_MFD_TIMEOUT;
                    end end else if (fmd_timeout) begin
                        fifo_fmc_wr = 1'b1;
                        event_error = 1'b1;
                        creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_FMD_TIMEOUT;
                    end end else if (fmd_vld) begin
                        if (fmd_parity_fail) begin
                            fifo_fmc_wr = 1'b1;
                            event_error = 1'b1;
                            creg_errcode_next = `PRGA_YAMI_CREG_ERRCODE_PARITY;
                        end else begin
                            fifo_fmc_wr = 1'b1;
                            fifo_fmc_data = { FMC_DATA_PER_FIFO_ELEM {fmd_data} };
                        end
                    end
                end else begin
                    // fill in dummy data
                    fifo_fmc_wr = 1'b1;
                end

                if (fifo_fmc_wr && !fifo_fmc_full) begin
                    if (fmc_payload) begin
                        fmc_payload_next = fmc_payload - 1;
                    end else if (event_error || !yami_active) begin
                        fmc_state_next = FMC_STATE_ERROR_PENDING;
                    end else begin
                        fmc_state_next = FMC_STATE_IDLE;
                    end
                end
            end

        endcase
    end

endmodule
