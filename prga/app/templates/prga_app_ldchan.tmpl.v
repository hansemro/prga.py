// Automatically generated by PRGA's RTL generator
`timescale 1ns/1ps
`include "prga_utils.vh"
`include "prga_app_memintf.vh"

/*
* Load channel. 
*
*   Perform memory loads through a simple val/rdy interface, then push data
*   through the kernel val/rdy interface.
*
*   This design is used to initiate memory loads in "transaction" s. Each
*   "transaction" loads one "object" in the default mode, or a stream of
*   "object" s if `enable_stream` is turned on during RTL generation. An
*   "object" is a consecutive chunk of memory, whose size must be a multiple of
*   the kernel data channel width ("kunit"), and the base address must be
*   natually aligned to the kernel data channel width as well.
*
*   Examples (suppose `ldresp_data` is 8B (64-bit) wide):
*       1. Single-kunit (4B) object + non-streaming transaction: `kernel_data` is
*          32-bit wide; `obj_base_addr` must be aligned to 4B address; each
*          transaction includes one load to the main memory, and one push to
*          the kernel
*       2. Single-kunit (16B) object + non-streaming transaction: `kernel_data`
*          is 128-bit wide; `obj_base_addr` must be aligned to 8B address; each
*          transaction includes 2 loads to the main memory, but only one push to
*          the kernel
*       3. 256-kunit (4B per kunit) object + non-streaming transaction:
*          `kernel_data` is 32-bit wide; each transaction includes 128 loads to
*          the main memory (or 129 if the base address is aligned to 4B but not
*          8B), and 256 pushes to the kernel. A good example would be to read in
*          a 32x32 gray-scale image
*
*   The key difference between streaming and object size is that, streaming
*   object counts are runtime configurable, while the object size is
*   paramterized during synthesis.
*
*   Endianness and byte ordering: the kernel is assumed to be consistent with
*   the memory.
*
*   TODO:
*       - Add support for streaming mode
*/

module prga_app_ldchan #(
    parameter   KERNEL_DATA_BYTES_LOG2      =   2   // 4B by default
    , parameter OBJ_SIZE                    =   0   // actual size = ((OBJ_SIZE + 1) << KERNEL_DATA_BYTES_LOG2) bytes
) (
    input wire                                                  clk
    , input wire                                                rst_n

    // == Memory-side Val/Rdy Interface =======================================
    , input wire                                                ldreq_rdy
    , output reg                                                ldreq_val
    , output reg [`PRGA_APP_MEMINTF_ADDR_WIDTH-1:0]             ldreq_addr

    , output reg                                                ldresp_rdy
    , input wire                                                ldresp_val
    , input wire [`PRGA_APP_MEMINTF_DATA_WIDTH-1:0]             ldresp_data

    // == Kernel-side Interface ===============================================
    , input wire                                                kernel_rdy
    , output reg                                                kernel_val
    , output reg [(1 << (KERNEL_DATA_BYTES_LOG2+3))-1:0]        kernel_data

    // == Memory Transaction Configurations ===================================

    // Transaction hand-shake
    , input wire                                                trx_start
    , output wire                                               trx_busy

    // Base address of the memory object. Must be natually aligned
    , input wire [`PRGA_APP_MEMINTF_ADDR_WIDTH-1:0]             obj_base_addr
    );

    // ========================================================================
    // -- Local Parameters ----------------------------------------------------
    // ========================================================================

    localparam  OBJ_SIZE_LOG2       = (OBJ_SIZE == 0) ? 0 : `PRGA_CLOG2(OBJ_SIZE + 1);

    localparam  KERNEL_DATA_BYTES   = 1 << KERNEL_DATA_BYTES_LOG2;
    localparam  KERNEL_DATA_WIDTH   = KERNEL_DATA_BYTES * 8;

    localparam  LOADS_PER_KUNIT_LOG2    = (KERNEL_DATA_BYTES_LOG2 > `PRGA_APP_MEMINTF_DATA_BYTES_LOG2) ?
                                          (KERNEL_DATA_BYTES_LOG2 - `PRGA_APP_MEMINTF_DATA_BYTES_LOG2) : 0;

    localparam  MAX_KUNITS_PER_LOAD_LOG2    = (`PRGA_APP_MEMINTF_DATA_BYTES_LOG2 > KERNEL_DATA_BYTES_LOG2) ?
                                              (`PRGA_APP_MEMINTF_DATA_BYTES_LOG2 - KERNEL_DATA_BYTES_LOG2) : 0;
    localparam  MAX_KUNITS_PER_LOAD         = 1 << MAX_KUNITS_PER_LOAD_LOG2;

    localparam  FULLWORD_LD_ADDR_WIDTH      = `PRGA_APP_MEMINTF_ADDR_WIDTH - `PRGA_APP_MEMINTF_DATA_BYTES_LOG2;

    // ========================================================================
    // -- Request Channel -----------------------------------------------------
    // ========================================================================

    // Notes: We only need to send out the correct amount of requests.
    reg                                 req_active;     // 2-state FSM
    reg [FULLWORD_LD_ADDR_WIDTH-1:0]    req_addr;       // always issue full width load requests

    generate if (OBJ_SIZE == 0) begin
        if (LOADS_PER_KUNIT_LOG2 == 0) begin
            // Simplest case: each memory object is one kunit, and each kunit only
            // requires one load

            always @(posedge clk) begin
                if (~rst_n) begin
                    req_active <= 1'b0;
                    req_addr <= { FULLWORD_LD_ADDR_WIDTH {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    req_active <= 1'b1;
                    req_addr <= obj_base_addr[`PRGA_APP_MEMINTF_ADDR_WIDTH-1:`PRGA_APP_MEMINTF_DATA_BYTES_LOG2];
                end else if (ldreq_val && ldreq_rdy) begin
                    req_active <= 1'b0;
                end
            end

        end else begin
            // Slightly more complex case: each memory object is one kunit, but
            // each kunit requires multiple loads

            reg [LOADS_PER_KUNIT_LOG2-1:0] req_load_cnt;

            always @(posedge clk) begin
                if (~rst_n) begin
                    req_active <= 1'b0;
                    req_load_cnt <= { LOADS_PER_KUNIT_LOG2 {1'b0} };
                    req_addr <= { FULLWORD_LD_ADDR_WIDTH {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    req_active <= 1'b1;
                    req_load_cnt <= { LOADS_PER_KUNIT_LOG2 {1'b0} };
                    req_addr <= obj_base_addr[`PRGA_APP_MEMINTF_ADDR_WIDTH-1:`PRGA_APP_MEMINTF_DATA_BYTES_LOG2];
                end else if (ldreq_val && ldreq_rdy) begin
                    req_active <= ~&req_load_cnt;   // because kunit and memory data width are both power of 2
                    req_load_cnt <= req_load_cnt + 1;
                    req_addr <= req_addr + 1;
                end
            end

        end
    end else begin
        if (MAX_KUNITS_PER_LOAD_LOG2 == 0) begin
            // Kunit is equal to or larger than the memory data width. this is
            // the easy case when OBJ_SIZE > 0.

            reg [LOADS_PER_KUNIT_LOG2 + OBJ_SIZE_LOG2-1:0]  req_load_cnt;

            always @(posedge clk) begin
                if (~rst_n) begin
                    req_active <= 1'b0;
                    req_load_cnt <= { (LOADS_PER_KUNIT_LOG2 + OBJ_SIZE_LOG2) {1'b0} };
                    req_addr <= { FULLWORD_LD_ADDR_WIDTH {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    req_active <= 1'b1;
                    req_load_cnt <= { (LOADS_PER_KUNIT_LOG2 + OBJ_SIZE_LOG2) {1'b0} };
                    req_addr <= obj_base_addr[`PRGA_APP_MEMINTF_ADDR_WIDTH-1:`PRGA_APP_MEMINTF_DATA_BYTES_LOG2];
                end else if (ldreq_val && ldreq_rdy) begin
                    // LOADS_PER_KUNIT_LOG2 might be 0!
                    req_active <= req_load_cnt + 1 < ((OBJ_SIZE + 1) << LOADS_PER_KUNIT_LOG2);
                    req_load_cnt <= req_load_cnt + 1;
                    req_addr <= req_addr + 1;
                end
            end

        end else begin
            // The number of loads needed depends on lower bits of the base
            // address.. hate it

            reg [MAX_KUNITS_PER_LOAD_LOG2-1:0]  req_kunit_offset;
            reg [OBJ_SIZE_LOG2-1:0]             req_kunit_cnt;

            always @(posedge clk) begin
                if (~rst_n) begin
                    req_active <= 1'b0;
                    req_kunit_offset <= { MAX_KUNITS_PER_LOAD_LOG2 {1'b0} };
                    req_kunit_cnt <= { OBJ_SIZE_LOG2 {1'b0} };
                    req_addr <= { FULLWORD_LD_ADDR_WIDTH {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    req_active <= 1'b1;
                    req_kunit_offset <= obj_base_addr[`PRGA_APP_MEMINTF_DATA_BYTES_LOG2-1 -: MAX_KUNITS_PER_LOAD_LOG2];
                    req_kunit_cnt <= { OBJ_SIZE_LOG2 {1'b0} };
                    req_addr <= obj_base_addr[`PRGA_APP_MEMINTF_ADDR_WIDTH-1:`PRGA_APP_MEMINTF_DATA_BYTES_LOG2];
                end else if (ldreq_val && ldreq_rdy) begin
                    // note: object size = OBJ_SIZE + 1
                    req_active <= req_kunit_cnt + (1 << MAX_KUNITS_PER_LOAD_LOG2) <= OBJ_SIZE + req_kunit_offset;
                    req_kunit_offset <= { MAX_KUNITS_PER_LOAD_LOG2 {1'b0} };
                    req_kunit_cnt <= req_kunit_cnt + (1 << MAX_KUNITS_PER_LOAD_LOG2) - req_kunit_offset;
                    req_addr <= req_addr + 1;
                end
            end

        end
    end

    always @* begin
        ldreq_val = req_active;
        ldreq_addr = {req_addr, {`PRGA_APP_MEMINTF_DATA_BYTES_LOG2 {1'b0} }};
    end

    // ========================================================================
    // -- Response Channel ----------------------------------------------------
    // ========================================================================

    reg kernel_active;    // 2-state FSM

    generate if (MAX_KUNITS_PER_LOAD_LOG2 == 0) begin
        // full words are used from load response

        if (LOADS_PER_KUNIT_LOG2 == 0 && OBJ_SIZE == 0) begin
            // each load corresponds to one memory object

            always @(posedge clk) begin
                if (~rst_n) begin
                    kernel_active <= 1'b0;
                end else if (trx_start && !trx_busy) begin
                    kernel_active <= 1'b1;
                end else if (kernel_rdy && kernel_val) begin
                    kernel_active <= 1'b0;
                end
            end

            always @* begin
                ldresp_rdy = kernel_rdy && kernel_active;
                kernel_val = ldresp_val && kernel_active;
                kernel_data = ldresp_data;
            end

        end else if (LOADS_PER_KUNIT_LOG2 == 0) begin
            // multiple loads are needed per memory object, but each load
            // corresponds to one kunit

            reg [OBJ_SIZE_LOG2-1:0]         resp_load_cnt;

            always @(posedge clk) begin
                if (~rst_n) begin
                    kernel_active <= 1'b0;
                    resp_load_cnt <= { OBJ_SIZE_LOG2 {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    kernel_active <= 1'b1;
                    resp_load_cnt <= { OBJ_SIZE_LOG2 {1'b0} };
                end else if (kernel_rdy && kernel_val) begin
                    kernel_active <= resp_load_cnt < OBJ_SIZE;
                    resp_load_cnt <= resp_load_cnt + 1;
                end
            end

            always @* begin
                ldresp_rdy = kernel_rdy && kernel_active;
                kernel_val = ldresp_val && kernel_active;
                kernel_data = ldresp_data;
            end

        end else begin
            // multiple loads per kunit

            reg                             resp_active;    // 2-state FSM
            reg [LOADS_PER_KUNIT_LOG2-1:0]  resp_load_cnt;
            reg [OBJ_SIZE_LOG2-1:0]         resp_kunit_cnt;

            always @(posedge clk) begin
                if (~rst_n) begin
                    kernel_active <= 1'b0;
                    resp_kunit_cnt <= { OBJ_SIZE_LOG2 {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    kernel_active <= 1'b1;
                    resp_kunit_cnt <= { OBJ_SIZE_LOG2 {1'b0} };
                end else if (kernel_val && kernel_rdy) begin
                    kernel_active <= resp_kunit_cnt < OBJ_SIZE;
                    resp_kunit_cnt <= resp_kunit_cnt + 1;
                end
            end

            always @(posedge clk) begin
                if (~rst_n) begin
                    resp_active <= 1'b0;
                    resp_load_cnt <= { LOADS_PER_KUNIT_LOG2 {1'b0} };
                    kernel_val <= 1'b0;
                end else if (trx_start && !trx_busy) begin
                    resp_active <= 1'b1;
                    resp_load_cnt <= { LOADS_PER_KUNIT_LOG2 {1'b0} };
                    kernel_val <= 1'b0;
                end else if (ldresp_rdy && ldresp_val) begin
                    resp_active <= ~&resp_load_cnt
                                   || (resp_kunit_cnt + kernel_val) < OBJ_SIZE;
                    {kernel_val, resp_load_cnt} <= resp_load_cnt + 1;
                end else if (kernel_rdy) begin
                    kernel_val <= 1'b0;
                end
            end

            always @(posedge clk) begin
                if (~rst_n) begin
                    kernel_data <= { KERNEL_DATA_WIDTH {1'b0} };
                end else if (ldresp_rdy && ldresp_val) begin
                    kernel_data <= {ldresp_data, kernel_data} >> `PRGA_APP_MEMINTF_DATA_WIDTH;
                end
            end

            always @* begin
                ldresp_rdy = resp_active && |resp_load_cnt || ~kernel_val || kernel_rdy;
            end

        end

    end else begin
        // sub-word slicing is necessary.. hate it
        reg [MAX_KUNITS_PER_LOAD_LOG2-1:0]      resp_kunit_offset;
        reg [`PRGA_APP_MEMINTF_DATA_WIDTH-1:0]  resp_data_f;
        wire [KERNEL_DATA_WIDTH-1:0]            resp_kunits  [0:MAX_KUNITS_PER_LOAD-1];

        genvar resp_kunit_i;
        for (resp_kunit_i = 0; resp_kunit_i < MAX_KUNITS_PER_LOAD; resp_kunit_i = resp_kunit_i + 1) begin
            assign resp_kunits[resp_kunit_i] = resp_data_f[resp_kunit_i * KERNEL_DATA_WIDTH +: KERNEL_DATA_WIDTH];
        end

        always @* begin
            kernel_data = resp_kunits[resp_kunit_offset];
        end

        if (OBJ_SIZE == 0) begin
            // one memory object per load is guaranteed

            always @(posedge clk) begin
                if (~rst_n) begin
                    kernel_active <= 1'b0;
                    resp_kunit_offset <= { MAX_KUNITS_PER_LOAD_LOG2 {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    kernel_active <= 1'b1;
                    resp_kunit_offset <= obj_base_addr[`PRGA_APP_MEMINTF_DATA_BYTES_LOG2-1 -: MAX_KUNITS_PER_LOAD_LOG2];
                end else if (kernel_rdy && kernel_val) begin
                    kernel_active <= 1'b0;
                end
            end

            always @* begin
                ldresp_rdy = kernel_rdy && kernel_active;
                kernel_val = ldresp_val && kernel_active;
                resp_data_f = ldresp_data;
            end

        end else begin
            // one memory object may require multiple loads

            reg                             resp_active;    // 2-state FSM
            reg [OBJ_SIZE_LOG2-1:0]         resp_kunit_cnt;

            always @(posedge clk) begin
                if (~rst_n) begin
                    kernel_active <= 1'b0;
                    resp_kunit_offset <= { MAX_KUNITS_PER_LOAD_LOG2 {1'b0} };
                    resp_kunit_cnt <= { OBJ_SIZE_LOG2 {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    kernel_active <= 1'b1;
                    resp_kunit_offset <= obj_base_addr[`PRGA_APP_MEMINTF_DATA_BYTES_LOG2-1 -: MAX_KUNITS_PER_LOAD_LOG2];
                    resp_kunit_cnt <= { OBJ_SIZE_LOG2 {1'b0} };
                end else if (kernel_rdy && kernel_val) begin
                    kernel_active <= resp_kunit_cnt < OBJ_SIZE;
                    resp_kunit_offset <= resp_kunit_offset + 1;
                    resp_kunit_cnt <= resp_kunit_cnt + 1;
                end
            end

            always @(posedge clk) begin
                if (~rst_n) begin
                    resp_active <= 1'b0;
                    kernel_val <= 1'b0;
                    resp_data_f <= { `PRGA_APP_MEMINTF_DATA_WIDTH {1'b0} };
                end else if (trx_start && !trx_busy) begin
                    resp_active <= 1'b1;
                end else if (ldresp_rdy && ldresp_val) begin
                    resp_active <= resp_kunit_cnt + MAX_KUNITS_PER_LOAD - resp_kunit_offset <= OBJ_SIZE;
                    kernel_val <= 1'b1;
                    resp_data_f <= ldresp_data;
                end else if (kernel_rdy && &resp_kunit_offset) begin
                    kernel_val <= 1'b0;
                end
            end

            always @* begin
                ldresp_rdy = resp_active && (~kernel_val || (&resp_kunit_offset && kernel_rdy));
            end

        end

    end endgenerate

    // ========================================================================
    // -- Transaction Hand-Shake ----------------------------------------------
    // ========================================================================

    assign trx_busy = kernel_active;

endmodule
