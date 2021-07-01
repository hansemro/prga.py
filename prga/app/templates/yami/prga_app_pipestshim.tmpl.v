// Automatically generated by PRGA's RTL generator
`include "prga_yami.vh"

/*
* Pipelined store shim for a simple valid-ready master.
*/

module {{ module.name }} #(
    parameter   KERNEL_DATA_BYTES_LOG2 = {{ ((module.ports.kdata|length) // 8 - 1).bit_length() }}
) (
    input wire                                      clk
    , input wire                                    rst_n

    // == Control (Soft Registers) ===========================================
    , input wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]    cfg_addr    // base address
    , input wire [31:0]                             cfg_len     // # elements to store
    , input wire                                    cfg_start
    , output wire                                   cfg_idle

    // == Kernel-side Interface ==============================================
    , output wire                                   krdy
    , input wire                                    kvld
    , input wire [(8<<KERNEL_DATA_BYTES_LOG2)-1:0]  kdata

    // == Memory-side YAMI Interface =========================================
    // -- FMC (fabric-memory channel) ----------------------------------------
    , input wire                                    fmc_rdy
    , output reg                                    fmc_vld
    , output wire [`PRGA_YAMI_REQTYPE_WIDTH-1:0]    fmc_type
    , output wire [`PRGA_YAMI_SIZE_WIDTH-1:0]       fmc_size
    , output wire [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0]   fmc_addr
    , output wire [`PRGA_YAMI_FMC_DATA_WIDTH-1:0]   fmc_data

    // -- MFC (memory-fabric channel) ----------------------------------------
    , output wire                                   mfc_rdy
    , input wire                                    mfc_vld
    // fixed transactions, ignore response type
    // , input wire [`PRGA_YAMI_RESPTYPE_WIDTH-1:0]    mfc_type
    // store shim, ignore response data
    // , input wire [`PRGA_YAMI_MFC_DATA_WIDTH-1:0]    mfc_data
    // cache is not supported beyond this shim
    // , input wire [`PRGA_YAMI_MFC_ADDR_WIDTH-1:0]    mfc_addr
    );

    // == kernel -> FMC ======================================================
    localparam  QST_WIDTH   = 2;
    localparam  QST_RST     = 2'h0,
                QST_IDLE    = 2'h1,
                QST_BUSY    = 2'h2;

    reg [QST_WIDTH-1:0]                 req_state, req_state_next;
    reg [`PRGA_YAMI_FMC_ADDR_WIDTH-1:0] req_addr,  req_addr_next;
    reg [31:0]                          req_len,   req_len_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            req_state   <= QST_RST;
            req_addr    <= { `PRGA_YAMI_FMC_ADDR_WIDTH {1'b0} };
            req_len     <= 32'h0;
        end else begin
            req_state   <= req_state_next;
            req_addr    <= req_addr_next;
            req_len     <= req_len_next;
        end
    end

    assign fmc_type = `PRGA_YAMI_REQTYPE_STORE;
    assign fmc_addr = req_addr;
    assign krdy = req_state == QST_BUSY && fmc_rdy;

    generate
        if (KERNEL_DATA_BYTES_LOG2 == 0) begin
            assign fmc_size = `PRGA_YAMI_SIZE_1B;
            assign fmc_data = {  `PRGA_YAMI_FMC_DATA_BYTES    {kdata} };
        end else if (KERNEL_DATA_BYTES_LOG2 == 1) begin
            assign fmc_size = `PRGA_YAMI_SIZE_2B;
            assign fmc_data = { (`PRGA_YAMI_FMC_DATA_BYTES/2) {kdata} };
        end else if (KERNEL_DATA_BYTES_LOG2 == 2) begin
            assign fmc_size = `PRGA_YAMI_SIZE_4B;
            assign fmc_data = { (`PRGA_YAMI_FMC_DATA_BYTES/4) {kdata} };
        end else if (KERNEL_DATA_BYTES_LOG2 == 3) begin
            assign fmc_size = `PRGA_YAMI_SIZE_8B;
            assign fmc_data = { (`PRGA_YAMI_FMC_DATA_BYTES/8) {kdata} };
        end else begin
            __PRGA_PARAMETERIZATION_ERROR__ __error__();
        end
    endgenerate

    always @* begin
        req_state_next  = req_state;
        req_addr_next   = req_addr;
        req_len_next    = req_len;

        fmc_vld         = 1'b0;

        case (req_state)
            QST_RST:    req_state_next = QST_IDLE;
            QST_IDLE: begin
                if (cfg_start && cfg_idle) begin
                    req_state_next  = QST_BUSY;
                    req_addr_next   = cfg_addr;
                    req_len_next    = cfg_len;
                end
            end
            QST_BUSY: begin
                fmc_vld = kvld;

                if (kvld && fmc_rdy) begin
                    if (req_len == 1) begin
                        req_state_next  = QST_IDLE;
                    end else begin
                        req_addr_next   = req_addr + (1 << KERNEL_DATA_BYTES_LOG2);
                        req_len_next    = req_len - 1;
                    end
                end
            end
        endcase
    end

    // == MFC ack ============================================================
    localparam  RST_WIDTH   = 2;
    localparam  RST_RST     = 2'h0,
                RST_IDLE    = 2'h1,
                RST_BUSY    = 2'h2;

    reg [RST_WIDTH-1:0] resp_state, resp_state_next;
    reg [31:0]          resp_len,   resp_len_next;

    always @(posedge clk) begin
        if (~rst_n) begin
            resp_state  <= RST_RST;
            resp_len    <= 32'h0;
        end else begin
            resp_state  <= resp_state_next;
            resp_len    <= resp_len_next;
        end
    end

    always @* begin
        resp_state_next = resp_state;
        resp_len_next   = resp_len;

        case (resp_state)
            RST_RST:    resp_state_next = RST_IDLE;
            RST_IDLE: begin
                if (cfg_start && cfg_idle) begin
                    resp_state_next = RST_BUSY;
                    resp_len_next   = cfg_len;
                end
            end
            RST_BUSY: begin
                if (mfc_vld) begin
                    if (resp_len == 1) begin
                        resp_state_next = RST_IDLE;
                    end else begin
                        resp_len_next   = resp_len - 1;
                    end
                end
            end
        endcase
    end

    assign cfg_idle = req_state == QST_IDLE && resp_state == RST_IDLE;
    assign mfc_rdy = resp_state == RST_BUSY;

endmodule
