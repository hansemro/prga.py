/*
* ============================================================================
* ==== PRGA YAMI* (Yet-Another-Memory-Interface) =============================
* ============================================================================
*
* -----------------------
*   * pronounced as "yummy"
*
* Introduction
* ------------
*
*   YAMI is a memory interface for PRGA-based eFPGAs.
*
*   YAMI interface consists of two (2) channels:
*   
*     - Fabric-Memory Channel (FMC)
*     - Memory-Fabric Channel (MFC)
*
*   Each channel employs a valid-ready handshake (valid and ready must be
*   combinationally independent on the memory side, thus tolerating
*   combinational dependency inside the fabric).
*
*   Each YAMI implementation may support only a subset of YAMI's transactions.
*   For example, we may see load-only YAMI, store-only YAMI, etc. This is
*   similar to only having AXI4 AR+R, or only having AXI4 AW+W+B.
*
*   YAMI supports atomic operations and write-through l1cache in the fabric.
*
*   Key features of YAMI include:
*
*     - MFC may have a wider data bus than FMC to better support l1cache. If the
*       cacheline size is larger than the MFC data bus, it's also possible to
*       compose a multi-flit MFC response.
*     - FMC has a baked-in parity check to detect FPGA malfunction
*     - MFC has a timer to detect FPGA malfunction
*     - YAMI has a baked-in register-based configuration interface (CREG) and
*       an error recording mechanism 
*
* Parameterization
* ----------------
*
*   * FMC_ADDR_WIDTH: address width (increment in bytes)
*   * FMC_DATA_BYTES: #Bytes of the FMC data bus. Valid values: 4, 8
*
*   * MFC_ADDR_WIDTH: invalidation address
*   * MFC_DATA_BYTES: #Bytes of the MFC data bus. Valid values: 4, 8, 16, 32.
*                       Must be greater than or equal to `FMC_DATA_BYTES`.
*
*   * YAMI_CACHELINE_BYTES: #Bytes of a cache line. Must be greater than or
*                       equal to `MFC_DATA_BYTES`.
*
*   FMC_ADDR_WIDTH/MFC_ADDR_WIDTH must be equal to or less than 48 
*
* Transaction Types
* -----------------
*
*   FMC (request) types: 5bits
*
*     - Available to the fabric:
*       - LOAD:     cacheable/non-cacheable
*       - STORE:    cacheable/non-cacheable
*       - INTERRUPT
*       - AMO types
*
*     - Used internally in a YAMI implementation to cross async fifo:
*       - CREG_ACK: ack to a ctrl register load/store request
*
*   MFC (response) types: 4bits
*
*     - Available to the fabric:
*       - LOAD_ACK
*       - STORE_ACK
*       - INTERRUPT_ACK
*       - AMO_ACK
*       - CACHE_INV
*
*     - Used internally in a YAMI implementation to cross async fifo:
*       - CREG_LOAD: load a ctrl register value
*       - CREG_STORE: store a ctrl register value
*
* Optional Features
* -----------------
*
*   * Non-cacheable accesses:
*   * Atomic operations:
*   * Soft cache (L1 cache)
*   * Subword transactions:
*   * Interrupts
*
* FMC channel
* -----------
*
*   An FMC channel must have the following ports (direction from the
*   fabric's point of view):
*
*     - input                       fmc_rdy
*     - output                      fmc_vld
*     - output [4:0]                fmc_type: request type
*     - output [FMC_ADDR_WIDTH-1:0] fmc_addr: request address
*     - output                      fmc_parity: odd parity
*
*   Optional:
*
*     - output [2:0]                fmc_size: request size
*         * full, 1B, 2B, 4B, 8B, 16B, 32B, cacheline
*     - output [FMC_DATA_WIDTH-1:0] fmc_data: request data
*         * when `fmc_size` is also supported, sub-word requests should be
*           replicated and filled. e.g. 1B write over an 8B interface:
*               data = {8{byte}}
*         * only needed if store/amo requests are supported
*
* MFC channel
* -----------
*
*   An MFC channel must have the following ports (direction from the
*   fabric's point of view):
*
*     - output                      mfc_rdy
*     - input                       mfc_vld
*     - input [3:0]                 mfc_type: response type
*
*   Optional:
*
*     - input [MFC_ADDR_WIDTH-1:0]  mfc_addr: invalidation address
*         * only needed if l1cache is supported
*     - input [MFC_DATA_WIDTH-1:0]  mfc_data: response data
*         * when `fmc_size` is also supported, sub-word requests should be
*           replicated and filled. e.g. 1B load over an 8B interface:
*               data = {8{byte}}
*         * if cacheline size is larger than MFC_DATA_WIDTH, multi-flit response
*           is possible (multiple LOAD_ACKs)
*
*/
`ifndef PRGA_YAMI_VH
`define PRGA_YAMI_VH

// -- Parameterized Macros ---------------------------------------------------
`define PRGA_YAMI_FMC_ADDR_WIDTH            {{ intf.fmc_addr_width }}
`define PRGA_YAMI_FMC_DATA_BYTES_LOG2       {{ intf.fmc_data_bytes_log2 }}

`define PRGA_YAMI_MFC_ADDR_WIDTH            {{ intf.mfc_addr_width }}
`define PRGA_YAMI_MFC_DATA_BYTES_LOG2       {{ intf.mfc_data_bytes_log2 }}

`define PRGA_YAMI_CACHELINE_BYTES_LOG2      {{ intf.cacheline_bytes_log2 }}

// -- Derived Macros ---------------------------------------------------------
`define PRGA_YAMI_FMC_DATA_BYTES            (1 << `PRGA_YAMI_FMC_DATA_BYTES_LOG2)
`define PRGA_YAMI_FMC_DATA_WIDTH            (8 << `PRGA_YAMI_FMC_DATA_BYTES_LOG2)

`define PRGA_YAMI_MFC_DATA_BYTES            (1 << `PRGA_YAMI_MFC_DATA_BYTES_LOG2)
`define PRGA_YAMI_MFC_DATA_WIDTH            (8 << `PRGA_YAMI_MFC_DATA_BYTES_LOG2)

`define PRGA_YAMI_CACHELINE_BYTES           (1 << `PRGA_YAMI_CACHELINE_BYTES_LOG2)
`define PRGA_YAMI_CACHELINE_WIDTH           (8 << `PRGA_YAMI_CACHELINE_BYTES_LOG2)

// -- Fixed Macros -----------------------------------------------------------
`define PRGA_YAMI_SIZE_WIDTH                3
`define PRGA_YAMI_SIZE_FULL                 `PRGA_YAMI_SIZE_WIDTH'b000  // use FMC_DATA_WIDTH for store and MFC_DATA_WIDTH for load
`define PRGA_YAMI_SIZE_1B                   `PRGA_YAMI_SIZE_WIDTH'b001
`define PRGA_YAMI_SIZE_2B                   `PRGA_YAMI_SIZE_WIDTH'b010
`define PRGA_YAMI_SIZE_4B                   `PRGA_YAMI_SIZE_WIDTH'b011
`define PRGA_YAMI_SIZE_8B                   `PRGA_YAMI_SIZE_WIDTH'b100
`define PRGA_YAMI_SIZE_16B                  `PRGA_YAMI_SIZE_WIDTH'b101
`define PRGA_YAMI_SIZE_32B                  `PRGA_YAMI_SIZE_WIDTH'b110
`define PRGA_YAMI_SIZE_CACHELINE            `PRGA_YAMI_SIZE_WIDTH'b111  // use CACHELINE_DATA_WIDTH for load

`define PRGA_YAMI_REQTYPE_WIDTH             5
`define PRGA_YAMI_REQTYPE_NONE              `PRGA_YAMI_REQTYPE_WIDTH'b00000
`define PRGA_YAMI_REQTYPE_CREG_ACK          `PRGA_YAMI_REQTYPE_WIDTH'b00001

`define PRGA_YAMI_REQTYPE_LOAD              `PRGA_YAMI_REQTYPE_WIDTH'b01010
`define PRGA_YAMI_REQTYPE_LOAD_NC           `PRGA_YAMI_REQTYPE_WIDTH'b01011

`define PRGA_YAMI_REQTYPE_STORE             `PRGA_YAMI_REQTYPE_WIDTH'b01100
`define PRGA_YAMI_REQTYPE_STORE_NC          `PRGA_YAMI_REQTYPE_WIDTH'b01101

`define PRGA_YAMI_REQTYPE_AMO_LR            `PRGA_YAMI_REQTYPE_WIDTH'b10001
`define PRGA_YAMI_REQTYPE_AMO_SC            `PRGA_YAMI_REQTYPE_WIDTH'b10010
`define PRGA_YAMI_REQTYPE_AMO_SWAP          `PRGA_YAMI_REQTYPE_WIDTH'b10011
`define PRGA_YAMI_REQTYPE_AMO_ADD           `PRGA_YAMI_REQTYPE_WIDTH'b10100
`define PRGA_YAMI_REQTYPE_AMO_AND           `PRGA_YAMI_REQTYPE_WIDTH'b10101
`define PRGA_YAMI_REQTYPE_AMO_OR            `PRGA_YAMI_REQTYPE_WIDTH'b10110
`define PRGA_YAMI_REQTYPE_AMO_XOR           `PRGA_YAMI_REQTYPE_WIDTH'b10111
`define PRGA_YAMI_REQTYPE_AMO_MAX           `PRGA_YAMI_REQTYPE_WIDTH'b11000
`define PRGA_YAMI_REQTYPE_AMO_MAXU          `PRGA_YAMI_REQTYPE_WIDTH'b11001
`define PRGA_YAMI_REQTYPE_AMO_MIN           `PRGA_YAMI_REQTYPE_WIDTH'b11010
`define PRGA_YAMI_REQTYPE_AMO_MINU          `PRGA_YAMI_REQTYPE_WIDTH'b11011
// `define PRGA_YAMI_REQTYPE_AMO_CAS1          `PRGA_YAMI_REQTYPE_WIDTH'b11100
// `define PRGA_YAMI_REQTYPE_AMO_CAS2          `PRGA_YAMI_REQTYPE_WIDTH'b11101

`define PRGA_YAMI_RESPTYPE_WIDTH            4
`define PRGA_YAMI_RESPTYPE_NONE             `PRGA_YAMI_RESPTYPE_WIDTH'b0000
`define PRGA_YAMI_RESPTYPE_CREG_LOAD        `PRGA_YAMI_RESPTYPE_WIDTH'b0010
`define PRGA_YAMI_RESPTYPE_CREG_STORE       `PRGA_YAMI_RESPTYPE_WIDTH'b0001
`define PRGA_YAMI_RESPTYPE_LOAD_ACK         `PRGA_YAMI_RESPTYPE_WIDTH'b1001
`define PRGA_YAMI_RESPTYPE_STORE_ACK        `PRGA_YAMI_RESPTYPE_WIDTH'b1010
`define PRGA_YAMI_RESPTYPE_CACHE_INV        `PRGA_YAMI_RESPTYPE_WIDTH'b1011
`define PRGA_YAMI_RESPTYPE_AMO_ACK          `PRGA_YAMI_RESPTYPE_WIDTH'b1100

// -- Ctrl Registers ---------------------------------------------------------
`define PRGA_YAMI_CREG_ADDR_WIDTH           2   // only 4 registers
`define PRGA_YAMI_CREG_DATA_BYTES           `PRGA_YAMI_FMC_DATA_BYTES
`define PRGA_YAMI_CREG_DATA_WIDTH           `PRGA_YAMI_FMC_DATA_WIDTH

`define PRGA_YAMI_CREG_ADDR_STATUS          `PRGA_YAMI_CREG_ADDR_WIDTH'h0
`define PRGA_YAMI_CREG_ADDR_FEATURES        `PRGA_YAMI_CREG_ADDR_WIDTH'h1
`define PRGA_YAMI_CREG_ADDR_TIMEOUT         `PRGA_YAMI_CREG_ADDR_WIDTH'h2
`define PRGA_YAMI_CREG_ADDR_ERRCODE         `PRGA_YAMI_CREG_ADDR_WIDTH'h3

`define PRGA_YAMI_CREG_STATUS_WIDTH         2
`define PRGA_YAMI_CREG_STATUS_RESET         `PRGA_YAMI_CREG_STATUS_WIDTH'b00
`define PRGA_YAMI_CREG_STATUS_INACTIVE      `PRGA_YAMI_CREG_STATUS_WIDTH'b01
`define PRGA_YAMI_CREG_STATUS_ACTIVE        `PRGA_YAMI_CREG_STATUS_WIDTH'b10
`define PRGA_YAMI_CREG_STATUS_ERROR         `PRGA_YAMI_CREG_STATUS_WIDTH'b11

`define PRGA_YAMI_CREG_FEATURE_WIDTH        24
`define PRGA_YAMI_CREG_FEATURE_BIT_LOAD     0
`define PRGA_YAMI_CREG_FEATURE_BIT_STORE    1
`define PRGA_YAMI_CREG_FEATURE_BIT_SUBWORD  2
`define PRGA_YAMI_CREG_FEATURE_BIT_NC       3
`define PRGA_YAMI_CREG_FEATURE_BIT_AMO      4
`define PRGA_YAMI_CREG_FEATURE_BIT_L1CACHE  5

`define PRGA_YAMI_CREG_FEATURE_LOAD         (`PRGA_YAMI_CREG_FEATURE_WIDTH'h1 << `PRGA_YAMI_CREG_FEATURE_BIT_LOAD)
`define PRGA_YAMI_CREG_FEATURE_STORE        (`PRGA_YAMI_CREG_FEATURE_WIDTH'h1 << `PRGA_YAMI_CREG_FEATURE_BIT_STORE)
`define PRGA_YAMI_CREG_FEATURE_SUBWORD      (`PRGA_YAMI_CREG_FEATURE_WIDTH'h1 << `PRGA_YAMI_CREG_FEATURE_BIT_SUBWORD)
`define PRGA_YAMI_CREG_FEATURE_NC           (`PRGA_YAMI_CREG_FEATURE_WIDTH'h1 << `PRGA_YAMI_CREG_FEATURE_BIT_NC)
`define PRGA_YAMI_CREG_FEATURE_AMO          (`PRGA_YAMI_CREG_FEATURE_WIDTH'h1 << `PRGA_YAMI_CREG_FEATURE_BIT_AMO)
`define PRGA_YAMI_CREG_FEATURE_L1CACHE      (`PRGA_YAMI_CREG_FEATURE_WIDTH'h1 << `PRGA_YAMI_CREG_FEATURE_BIT_L1CACHE)

`define PRGA_YAMI_CREG_ERRCODE_WIDTH                32
`define PRGA_YAMI_CREG_ERRCODE_UNKNOWN              `PRGA_YAMI_CREG_ERRCODE_WIDTH'h00_000000
`define PRGA_YAMI_CREG_ERRCODE_TIMEOUT              `PRGA_YAMI_CREG_ERRCODE_WIDTH'h01_000000
`define PRGA_YAMI_CREG_ERRCODE_PARITY               `PRGA_YAMI_CREG_ERRCODE_WIDTH'h01_000001
`define PRGA_YAMI_CREG_ERRCODE_SIZE_OUT_OF_RANGE    `PRGA_YAMI_CREG_ERRCODE_WIDTH'h01_000002
`define PRGA_YAMI_CREG_ERRCODE_MISSING_FEATURES     `PRGA_YAMI_CREG_ERRCODE_WIDTH'h80_000000    // missing features should be added
`define PRGA_YAMI_CREG_ERRCODE_INVAL_REQTYPE        `PRGA_YAMI_CREG_ERRCODE_WIDTH'h81_000000    // reqtype should be added

// -- Async FIFO Elements ----------------------------------------------------
    /*  FMC FIFO Element
    *
    *           |<- 5bits ->|<- 3bits ->|<- FMC_ADDR_WIDTH ->|<- FMC_DATA_WIDTH ->|
    *           +-----------+-----------+--------------------+--------------------+
    *           |  reqtype  |    size   |    mem/creg addr   |    mem/creg data   |
    *           +-----------+-----------+--------------------+--------------------+
    *
    *   MFC FIFO Element
    *
    *           |<- 4bits ->|<- MFC_ADDR_WIDTH ->|<- MFC_DATA_WIDTH ->|
    *           +-----------+--------------------+--------------------+
    *           |  resptype |    mem/creg addr   |    mem/creg data   |
    *           +-----------+--------------------+--------------------+
    */

`define PRGA_YAMI_FMC_FIFO_ELEM_WIDTH   (`PRGA_YAMI_REQTYPE_WIDTH + `PRGA_YAMI_SIZE_WIDTH + `PRGA_YAMI_FMC_ADDR_WIDTH + `PRGA_YAMI_FMC_DATA_WIDTH)
`define PRGA_YAMI_MFC_FIFO_ELEM_WIDTH   (`PRGA_YAMI_RESPTYPE_WIDTH                        + `PRGA_YAMI_MFC_ADDR_WIDTH + `PRGA_YAMI_MFC_DATA_WIDTH)

`define PRGA_YAMI_FMC_FIFO_DATA_BASE        0
`define PRGA_YAMI_FMC_FIFO_ADDR_BASE        (`PRGA_YAMI_FMC_FIFO_DATA_BASE + `PRGA_YAMI_FMC_DATA_WIDTH)
`define PRGA_YAMI_FMC_FIFO_SIZE_BASE        (`PRGA_YAMI_FMC_FIFO_ADDR_BASE + `PRGA_YAMI_FMC_ADDR_WIDTH)
`define PRGA_YAMI_FMC_FIFO_REQTYPE_BASE     (`PRGA_YAMI_FMC_FIFO_SIZE_BASE + `PRGA_YAMI_SIZE_WIDTH)

`define PRGA_YAMI_FMC_FIFO_DATA_INDEX       `PRGA_YAMI_FMC_FIFO_DATA_BASE+:`PRGA_YAMI_FMC_DATA_WIDTH
`define PRGA_YAMI_FMC_FIFO_ADDR_INDEX       `PRGA_YAMI_FMC_FIFO_ADDR_BASE+:`PRGA_YAMI_FMC_ADDR_WIDTH
`define PRGA_YAMI_FMC_FIFO_SIZE_INDEX       `PRGA_YAMI_FMC_FIFO_SIZE_BASE+:`PRGA_YAMI_SIZE_WIDTH
`define PRGA_YAMI_FMC_FIFO_REQTYPE_INDEX    `PRGA_YAMI_FMC_FIFO_REQTYPE_BASE+:`PRGA_YAMI_REQTYPE_WIDTH

`define PRGA_YAMI_MFC_FIFO_DATA_BASE        0
`define PRGA_YAMI_MFC_FIFO_ADDR_BASE        (`PRGA_YAMI_MFC_FIFO_DATA_BASE + `PRGA_YAMI_MFC_DATA_WIDTH)
`define PRGA_YAMI_MFC_FIFO_RESPTYPE_BASE    (`PRGA_YAMI_MFC_FIFO_ADDR_BASE + `PRGA_YAMI_MFC_ADDR_WIDTH)

`define PRGA_YAMI_MFC_FIFO_DATA_INDEX       `PRGA_YAMI_MFC_FIFO_DATA_BASE+:`PRGA_YAMI_MFC_DATA_WIDTH
`define PRGA_YAMI_MFC_FIFO_CREG_DATA_INDEX  `PRGA_YAMI_MFC_FIFO_DATA_BASE+:`PRGA_YAMI_CREG_DATA_WIDTH
`define PRGA_YAMI_MFC_FIFO_ADDR_INDEX       `PRGA_YAMI_MFC_FIFO_ADDR_BASE+:`PRGA_YAMI_MFC_ADDR_WIDTH
`define PRGA_YAMI_MFC_FIFO_CREG_ADDR_INDEX  `PRGA_YAMI_MFC_FIFO_ADDR_BASE+:`PRGA_YAMI_CREG_ADDR_WIDTH
`define PRGA_YAMI_MFC_FIFO_RESPTYPE_INDEX   `PRGA_YAMI_MFC_FIFO_RESPTYPE_BASE+:`PRGA_YAMI_RESPTYPE_WIDTH

`endif /* `ifndef PRGA_YAMI_VH */