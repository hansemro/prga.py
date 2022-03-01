// Automatically generated by PRGA's RTL generator

/*
* Main pipeline, stage III for prga_yami_pitoncache.
*/

`include "prga_yami.vh"
`include "prga_yami_pitoncache.vh"
`default_nettype none

module prga_yami_pitoncache_pipeline_s3 (
    // -- System Ctrl --------------------------------------------------------
    input wire                                                  clk
    , input wire                                                rst_n

    // -- Shared outputs -----------------------------------------------------
    , output reg                                                stall_s3
    , output wire [`PRGA_YAMI_CACHE_INDEX_WIDTH-1:0]            index_s3
    , output reg [`PRGA_YAMI_CACHE_NUM_WAYS_LOG2-1:0]           way_s3
    , output reg [`PRGA_YAMI_SIZE_WIDTH-1:0]                    size_s3
    , output reg [`PRGA_YAMI_MTHREAD_ID_WIDTH-1:0]              thread_id_s3
    , output reg [`PRGA_YAMI_REQTYPE_WIDTH-1:0]                 reqtype_s3
    , output reg [`PRGA_YAMI_CACHE_ROB_NUM_ENTRIES_LOG2-1:0]    rob_entry_s3

    // -- From Stage II ------------------------------------------------------
    , input wire [`PRGA_YAMI_CACHE_S3OP_WIDTH-1:0]              op_s3_next
    , input wire [`PRGA_YAMI_CACHE_NUM_WAYS_LOG2-1:0]           inv_prq_way_s3_next
    , input wire [`PRGA_YAMI_MTHREAD_ID_WIDTH-1:0]              thread_id_s3_next
    , input wire [`PRGA_YAMI_REQTYPE_WIDTH-1:0]                 reqtype_s3_next
    , input wire [`PRGA_YAMI_SIZE_WIDTH-1:0]                    size_s3_next
    , input wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]                addr_s3_next
    , input wire [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]                data_s3_next
    , input wire [`PRGA_YAMI_CACHE_ROB_NUM_ENTRIES_LOG2-1:0]    rob_entry_s3_next

    // -- To State Array -----------------------------------------------------
    , output reg [`PRGA_YAMI_CACHE_S3OP_SA_WIDTH-1:0]           state_array_op_s3

    // -- To Tag Array -------------------------------------------------------
    , output reg                                                tag_array_wr_s3
    , output wire [`PRGA_YAMI_CACHE_TAG_WIDTH-1:0]              tag_s3

    // -- To LRU Array -------------------------------------------------------
    , output reg                                                lru_array_wr_s3

    // -- To Data Array ------------------------------------------------------
    , input wire [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]                data_array_rdata_s3

    , output reg                                                data_array_wr_s3
    , output wire [`PRGA_YAMI_MFC_DATA_BYTES-1:0]               data_array_wstrb_s3
    , output wire [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]               data_array_wdata_s3

    // -- To ROB (Response reOrder Buffer) -----------------------------------
    , output reg [`PRGA_YAMI_NUM_MTHREADS-1:0]                  rob_fill_s3         // per thread
    , output reg [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]                rob_fill_data_s3

    // -- From Way Logic -----------------------------------------------------
    , input wire                                                hit_s3
    , input wire                                                iv_s3
    , input wire [`PRGA_YAMI_CACHE_NUM_WAYS_LOG2-1:0]           hit_rpl_way_s3

    // -- To RPB (RePlay Buffer) ---------------------------------------------
    , output reg                                                enqueue_rpb_s3
    , output wire [`PRGA_YAMI_MTHREAD_ID_WIDTH-1:0]             rpb_thread_id_s3
    // , output wire [`PRGA_YAMI_REQTYPE_WIDTH-1:0]                rpb_reqtype_s3      // reqtype_s3
    // , output wire [`PRGA_YAMI_SIZE_WIDTH-1:0]                   rpb_size_s3         // size_s3
    , output wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]               rpb_addr_s3
    , output wire [`PRGA_YAMI_FMC_DATA_WIDTH-1:0]               rpb_data_s3
    // , output wire [`PRGA_YAMI_CACHE_ROB_NUM_ENTRIES_LOG2-1:0]   rpb_rob_entry_s1    // rob_entry_s3

    // -- To PRQ (Pending Response Queue) ------------------------------------
    // full-flag checked at S1
    , output reg [`PRGA_YAMI_NUM_MTHREADS-1:0]                  prq_wr_s3           // per thread
    // , output wire [`PRGA_YAMI_CACHE_INDEX_WIDTH-1:0]            prq_index_s3        // index_s3
    // , output wire [`PRGA_YAMI_CACHE_NUM_WAYS_LOG2-1:0]          prq_way_s3          // hit_rpl_way_s3
    , output wire [`PRGA_YAMI_CACHE_INDEX_LOW-1:0]              prq_offset_s3
    // , output wire [`PRGA_YAMI_SIZE_WIDTH-1:0]                   prq_size_s3         // size_s3
    // , output wire [`PRGA_YAMI_CACHE_ROB_NUM_ENTRIES_LOG2-1:0]   prq_rob_entry_s3    // rob_entry_s3

    // -- Send FMC Requests to Memory ----------------------------------------
    , input wire                                                m_fmc_rdy
    , output reg                                                m_fmc_vld
    // , output wire [`PRGA_YAMI_MTHREAD_ID_WIDTH-1:0]             m_fmc_thread_id     // thread_id_s3
    // , output wire [`PRGA_YAMI_REQTYPE_WIDTH-1:0]                m_fmc_type          // reqtype_s3
    , output wire [`PRGA_YAMI_SIZE_WIDTH-1:0]                   m_fmc_size
    , output wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]               m_fmc_addr
    , output wire [`PRGA_YAMI_FMC_DATA_WIDTH-1:0]               m_fmc_data
    // , output wire [`PRGA_YAMI_CACHE_NUM_WAYS_LOG2-1:0]          m_fmc_rpl_way       // hit_rpl_way_s3
    );

    generate
        if (`PRGA_YAMI_MFC_DATA_BYTES_LOG2 != 4) begin
            __PRGA_MACRO_ERROR__ __error__();
        end
    endgenerate

    reg [`PRGA_YAMI_CACHE_S3OP_WIDTH-1:0]       op_s3;
    reg [`PRGA_YAMI_CACHE_NUM_WAYS_LOG2-1:0]    inv_prq_way_s3;
    reg [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]         addr_s3;
    reg [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]         data_s3;

    always @(posedge clk) begin
        if (~rst_n) begin
            op_s3           <= `PRGA_YAMI_CACHE_S3OP_NONE;
            thread_id_s3    <= { `PRGA_YAMI_MTHREAD_ID_WIDTH {1'b0} };
            inv_prq_way_s3  <= { `PRGA_YAMI_CACHE_NUM_WAYS_LOG2 {1'b0} };
            reqtype_s3      <= `PRGA_YAMI_REQTYPE_NONE;
            size_s3         <= `PRGA_YAMI_SIZE_FULL;
            addr_s3         <= { `PRGA_YAMI_FMC_ADDR_WIDTH {1'b0} };
            data_s3         <= { `PRGA_YAMI_MFC_DATA_WIDTH {1'b0} };
            rob_entry_s3    <= { `PRGA_YAMI_CACHE_ROB_NUM_ENTRIES_LOG2 {1'b0} };
        end else if (~stall_s3) begin
            op_s3           <= op_s3_next;
            thread_id_s3    <= thread_id_s3_next;
            inv_prq_way_s3  <= inv_prq_way_s3_next;
            reqtype_s3      <= reqtype_s3_next;
            size_s3         <= size_s3_next;
            addr_s3         <= addr_s3_next;
            data_s3         <= data_s3_next;
            rob_entry_s3    <= rob_entry_s3_next;
        end
    end

    reg data_array_wr_full_line, m_fmc_ld_full_line, rob_fill_data_use_rdata;

    always @* begin
        stall_s3            = 1'b0;
        way_s3              = inv_prq_way_s3;

        state_array_op_s3   = `PRGA_YAMI_CACHE_S3OP_SA_NONE;
        tag_array_wr_s3     = 1'b0;
        lru_array_wr_s3     = 1'b0;
        data_array_wr_s3    = 1'b0;

        rob_fill_s3                 = { `PRGA_YAMI_NUM_MTHREADS {1'b0} };
        data_array_wr_full_line     = 1'b0;
        m_fmc_ld_full_line          = 1'b0;
        rob_fill_data_use_rdata     = 1'b0;

        enqueue_rpb_s3      = 1'b0;
        prq_wr_s3           = { `PRGA_YAMI_NUM_MTHREADS {1'b0} };
        m_fmc_vld           = 1'b0;

        case (op_s3)
            `PRGA_YAMI_CACHE_S3OP_APP_REQ: begin
                case (reqtype_s3)
                    `PRGA_YAMI_REQTYPE_LOAD: begin
                        way_s3 = hit_rpl_way_s3;

                        // hit/miss (IV)
                        if (iv_s3) begin
                            enqueue_rpb_s3 = 1'b1;
                        end

                        // hit (V)
                        else if (hit_s3) begin
                            lru_array_wr_s3 = 1'b1;
                            rob_fill_s3[thread_id_s3] = 1'b1;
                            rob_fill_data_use_rdata = 1'b1;
                        end

                        // miss (V/I)
                        else begin
                            m_fmc_vld = 1'b1;   // send request to memory
                            m_fmc_ld_full_line = 1'b1;

                            if (m_fmc_rdy) begin
                                lru_array_wr_s3 = 1'b1;
                                tag_array_wr_s3 = 1'b1;
                                state_array_op_s3 = `PRGA_YAMI_CACHE_S3OP_SA_TRANSITION_TO_IV;
                                prq_wr_s3[thread_id_s3] = 1'b1;
                            end else begin
                                stall_s3 = 1'b1;
                            end
                        end
                    end

                    `PRGA_YAMI_REQTYPE_STORE: begin
                        way_s3 = hit_rpl_way_s3;

                        // hit (IV)
                        if (hit_s3 && iv_s3) begin
                            enqueue_rpb_s3 = 1'b1;
                        end

                        // hit on V, or miss
                        else begin
                            m_fmc_vld = 1'b1;   // send request to memory

                            if (m_fmc_rdy) begin
                                rob_fill_s3[thread_id_s3] = 1'b1;

                                if (hit_s3) begin
                                    lru_array_wr_s3 = 1'b1;
                                    data_array_wr_s3 = 1'b1;
                                end
                            end else begin
                                stall_s3 = 1'b1;
                            end
                        end
                    end
                    
                    `PRGA_YAMI_REQTYPE_AMO_LR,
                    `PRGA_YAMI_REQTYPE_AMO_SC,
                    `PRGA_YAMI_REQTYPE_AMO_SWAP,
                    `PRGA_YAMI_REQTYPE_AMO_ADD,
                    `PRGA_YAMI_REQTYPE_AMO_AND,
                    `PRGA_YAMI_REQTYPE_AMO_OR,
                    `PRGA_YAMI_REQTYPE_AMO_XOR,
                    `PRGA_YAMI_REQTYPE_AMO_MAX,
                    `PRGA_YAMI_REQTYPE_AMO_MAXU,
                    `PRGA_YAMI_REQTYPE_AMO_MIN,
                    `PRGA_YAMI_REQTYPE_AMO_MINU: begin
                        way_s3 = hit_rpl_way_s3;

                        // hit (IV)
                        if (hit_s3 && iv_s3) begin
                            enqueue_rpb_s3 = 1'b1;
                        end

                        // hit on V, or miss
                        else begin
                            m_fmc_vld = 1'b1;   // send request to memory

                            if (m_fmc_rdy) begin
                                prq_wr_s3[thread_id_s3] = 1'b1;
                                state_array_op_s3 = hit_s3 ? `PRGA_YAMI_CACHE_S3OP_INV_WAY :
                                                             `PRGA_YAMI_CACHE_S3OP_NONE;
                            end else begin
                                stall_s3 = 1'b1;
                            end
                        end
                    end

                    default: begin
                        $display ("[Error] |PRGA/YAMI/PitonCache| Unsupported FMC reqtype\n");
                        $stop;
                    end
                endcase
            end

            `PRGA_YAMI_CACHE_S3OP_INV_WAY: begin
                way_s3 = inv_prq_way_s3;
                state_array_op_s3 = `PRGA_YAMI_CACHE_S3OP_SA_INVAL_WAY;
            end

            `PRGA_YAMI_CACHE_S3OP_INV_ALL: begin
                way_s3 = inv_prq_way_s3;    // unnecessary
                state_array_op_s3 = `PRGA_YAMI_CACHE_S3OP_SA_INVAL_ALL;
            end

            `PRGA_YAMI_CACHE_S3OP_LD_ACK: begin
                rob_fill_s3[thread_id_s3] = 1'b1;
                rob_fill_data_use_rdata = 1'b0;
                way_s3 = inv_prq_way_s3;
                state_array_op_s3 = `PRGA_YAMI_CACHE_S3OP_SA_TRANSITION_TO_V;
                data_array_wr_s3 = 1'b1;
                data_array_wr_full_line = 1'b1;
            end

            `PRGA_YAMI_CACHE_S3OP_AMO_ACK: begin
                rob_fill_s3[thread_id_s3] = 1'b1;
                rob_fill_data_use_rdata = 1'b0;
            end
        endcase
    end

    assign index_s3             = addr_s3[`PRGA_YAMI_CACHE_INDEX_LOW +: `PRGA_YAMI_CACHE_INDEX_WIDTH];
    assign tag_s3               = addr_s3[`PRGA_YAMI_CACHE_TAG_LOW +: `PRGA_YAMI_CACHE_TAG_WIDTH];

    genvar gv_da_wstrb;
    generate
        for (gv_da_wstrb = 0; gv_da_wstrb < `PRGA_YAMI_MFC_DATA_BYTES; gv_da_wstrb = gv_da_wstrb + 1) begin: g_da_wstrb
            assign data_array_wstrb_s3[gv_da_wstrb] = data_array_wr_full_line ? 1'b1 :
                                                      size_s3 == `PRGA_YAMI_SIZE_1B ? (addr_s3[3:0] == gv_da_wstrb) :
                                                      size_s3 == `PRGA_YAMI_SIZE_2B ? (addr_s3[3:1] == gv_da_wstrb >> 1) :
                                                      size_s3 == `PRGA_YAMI_SIZE_4B ? (addr_s3[3:2] == gv_da_wstrb >> 2) :
                                                      size_s3 == `PRGA_YAMI_SIZE_8B ? (addr_s3[3]   == gv_da_wstrb >> 3) :
                                                                                      1'b1;
        end
    endgenerate

    assign data_array_wdata_s3  = data_s3;
    assign rpb_thread_id_s3     = thread_id_s3;
    assign rpb_addr_s3          = addr_s3;
    assign rpb_data_s3          = data_s3[0 +: `PRGA_YAMI_FMC_DATA_WIDTH];
    assign prq_offset_s3        = addr_s3[0+:`PRGA_YAMI_CACHE_INDEX_LOW];
    assign m_fmc_size           = m_fmc_ld_full_line ? `PRGA_YAMI_SIZE_16B : size_s3;
    assign m_fmc_addr           = m_fmc_size == `PRGA_YAMI_SIZE_1B  ? addr_s3 :
                                  m_fmc_size == `PRGA_YAMI_SIZE_2B  ? {addr_s3[`PRGA_YAMI_FMC_ADDR_WIDTH-1:1], 1'b0} :
                                  m_fmc_size == `PRGA_YAMI_SIZE_4B  ? {addr_s3[`PRGA_YAMI_FMC_ADDR_WIDTH-1:2], 2'b0} :
                                  m_fmc_size == `PRGA_YAMI_SIZE_8B  ? {addr_s3[`PRGA_YAMI_FMC_ADDR_WIDTH-1:3], 3'b0} :
                                  m_fmc_size == `PRGA_YAMI_SIZE_16B ? {addr_s3[`PRGA_YAMI_FMC_ADDR_WIDTH-1:4], 4'b0} :
                                                                      addr_s3;
    wire [`PRGA_YAMI_MFC_DATA_WIDTH-1:0] rob_fill_data_line;
    assign rob_fill_data_line = rob_fill_data_use_rdata ? data_array_rdata_s3 :
                                                          data_s3;

    always @* begin
        rob_fill_data_s3 = rob_fill_data_line;

        case (size_s3)
            `PRGA_YAMI_SIZE_1B: begin
                case (addr_s3[3:0])
                    4'h0: rob_fill_data_s3 = {16{rob_fill_data_line[  0+: 8]}};
                    4'h1: rob_fill_data_s3 = {16{rob_fill_data_line[  8+: 8]}};
                    4'h2: rob_fill_data_s3 = {16{rob_fill_data_line[ 16+: 8]}};
                    4'h3: rob_fill_data_s3 = {16{rob_fill_data_line[ 24+: 8]}};
                    4'h4: rob_fill_data_s3 = {16{rob_fill_data_line[ 32+: 8]}};
                    4'h5: rob_fill_data_s3 = {16{rob_fill_data_line[ 40+: 8]}};
                    4'h6: rob_fill_data_s3 = {16{rob_fill_data_line[ 48+: 8]}};
                    4'h7: rob_fill_data_s3 = {16{rob_fill_data_line[ 56+: 8]}};
                    4'h8: rob_fill_data_s3 = {16{rob_fill_data_line[ 64+: 8]}};
                    4'h9: rob_fill_data_s3 = {16{rob_fill_data_line[ 72+: 8]}};
                    4'ha: rob_fill_data_s3 = {16{rob_fill_data_line[ 80+: 8]}};
                    4'hb: rob_fill_data_s3 = {16{rob_fill_data_line[ 88+: 8]}};
                    4'hc: rob_fill_data_s3 = {16{rob_fill_data_line[ 96+: 8]}};
                    4'hd: rob_fill_data_s3 = {16{rob_fill_data_line[104+: 8]}};
                    4'he: rob_fill_data_s3 = {16{rob_fill_data_line[112+: 8]}};
                    4'hf: rob_fill_data_s3 = {16{rob_fill_data_line[120+: 8]}};
                endcase
            end

            `PRGA_YAMI_SIZE_2B: begin
                case (addr_s3[3:1])
                    3'h0: rob_fill_data_s3 = { 8{rob_fill_data_line[  0+:16]}};
                    3'h1: rob_fill_data_s3 = { 8{rob_fill_data_line[ 16+:16]}};
                    3'h2: rob_fill_data_s3 = { 8{rob_fill_data_line[ 32+:16]}};
                    3'h3: rob_fill_data_s3 = { 8{rob_fill_data_line[ 48+:16]}};
                    3'h4: rob_fill_data_s3 = { 8{rob_fill_data_line[ 64+:16]}};
                    3'h5: rob_fill_data_s3 = { 8{rob_fill_data_line[ 80+:16]}};
                    3'h6: rob_fill_data_s3 = { 8{rob_fill_data_line[ 96+:16]}};
                    3'h7: rob_fill_data_s3 = { 8{rob_fill_data_line[112+:16]}};
                endcase
            end

            `PRGA_YAMI_SIZE_4B: begin
                case (addr_s3[3:2])
                    2'h0: rob_fill_data_s3 = { 4{rob_fill_data_line[  0+:32]}};
                    2'h1: rob_fill_data_s3 = { 4{rob_fill_data_line[ 32+:32]}};
                    2'h2: rob_fill_data_s3 = { 4{rob_fill_data_line[ 64+:32]}};
                    2'h3: rob_fill_data_s3 = { 4{rob_fill_data_line[ 96+:32]}};
                endcase
            end

            `PRGA_YAMI_SIZE_8B: begin
                case (addr_s3[3])
                    1'h0: rob_fill_data_s3 = { 2{rob_fill_data_line[  0+:64]}};
                    1'h1: rob_fill_data_s3 = { 2{rob_fill_data_line[ 64+:64]}};
                endcase
            end
        endcase
    end

endmodule
