// Automatically generated by PRGA's RTL generator
`include "pktchain_axilite_intf.vh"
`timescale 1ns/1ps
module {{ module.name }} (
    // system ctrl signals
    input wire [0:0] clk,
    input wire [0:0] rst,

    // == AXI4-Lite Interface ================================================
    // write address channel
    input wire [0:0] m_AWVALID,
    output wire [0:0] m_AWREADY,
    input wire [`PRGA_AXI_ADDR_WIDTH - 1:0] m_AWADDR,
    input wire [2:0] m_AWPROT,

    // write data channel
    input wire [0:0] m_WVALID,
    output wire [0:0] m_WREADY,
    input wire [`PRGA_AXI_DATA_WIDTH - 1:0] m_WDATA,
    input wire [`PRGA_BYTES_PER_AXI_DATA - 1:0] m_WSTRB,

    // write response channel
    output wire [0:0] m_BVALID,
    input wire [0:0] m_BREADY,
    output wire [1:0] m_BRESP,

    // read address channel
    input wire [0:0] m_ARVALID,
    output wire [0:0] m_ARREADY,
    input wire [`PRGA_AXI_ADDR_WIDTH - 1:0] m_ARADDR,
    input wire [2:0] m_ARPROT,

    // read data channel
    output wire [0:0] m_RVALID,
    input wire [0:0] m_RREADY,
    output wire [`PRGA_AXI_DATA_WIDTH - 1:0] m_RDATA,
    output wire [1:0] m_RRESP,

    // == Configuration Backend Interface ====================================
    // programming interface
    output reg [0:0] cfg_rst,
    output reg [0:0] cfg_e,

    // configuration output
    input wire [0:0] cfg_phit_o_full,
    output wire [0:0] cfg_phit_o_wr,
    output wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] cfg_phit_o,

    // configuration input
    output wire [0:0] cfg_phit_i_full,
    input wire [0:0] cfg_phit_i_wr,
    input wire [`PRGA_PKTCHAIN_PHIT_WIDTH - 1:0] cfg_phit_i,

    // == User Backend Interface ============================================
    // user clock domain ctrl signals
    output reg [0:0] uclk,
    output wire [0:0] urst_n,

    // AXI4-Lite Interface
    output wire [0:0] u_AWVALID,
    input wire [0:0] u_AWREADY,
    output wire [`PRGA_AXI_ADDR_WIDTH - 1:0] u_AWADDR,
    output wire [2:0] u_AWPROT,

    // write data channel
    output wire [0:0] u_WVALID,
    input wire [0:0] u_WREADY,
    output wire [`PRGA_AXI_DATA_WIDTH - 1:0] u_WDATA,
    output wire [`PRGA_BYTES_PER_AXI_DATA - 1:0] u_WSTRB,

    // write response channel
    input wire [0:0] u_BVALID,
    output wire [0:0] u_BREADY,
    input wire [1:0] u_BRESP,

    // read address channel
    output wire [0:0] u_ARVALID,
    input wire [0:0] u_ARREADY,
    output wire [`PRGA_AXI_ADDR_WIDTH - 1:0] u_ARADDR,
    output wire [2:0] u_ARPROT,

    // read data channel
    input wire [0:0] u_RVALID,
    output wire [0:0] u_RREADY,
    input wire [`PRGA_AXI_DATA_WIDTH - 1:0] u_RDATA,
    input wire [1:0] u_RRESP
    );

    reg rst_f, soft_rst, rst_uclk;

    always @(posedge clk) begin
        rst_f <= rst;
    end

    always @(posedge uclk or posedge rst) begin
        if (rst) begin
            rst_uclk <= 'b1;
        end else begin
            rst_uclk <= 'b0;
        end
    end

    // generate user clock
    reg [7:0] uclk_div, uclk_div_cnt;

    // synopsys translate_off
    initial begin
        uclk = 'b0;
    end
    // synopsys translate_on

    always @(posedge clk) begin
        if (uclk_div_cnt == 0) begin    // this makes sure uclk runs during rst
            uclk <= ~uclk;
        end
    end

    always @(posedge clk) begin
        if (rst_f) begin
            uclk_div_cnt <= 'b0;
        end else if (uclk_div_cnt == 0) begin
            uclk_div_cnt <= uclk_div;
        end else begin
            uclk_div_cnt <= uclk_div_cnt - 1;
        end
    end

    // =======================================================================
    // -- Instances ----------------------------------------------------------
    // =======================================================================
    // Frontend
    wire i_fe_wreq_val, i_fe_wresp_rdy, i_fe_rreq_val, i_fe_rresp_rdy;
    wire i_fe_wreq_rdy, i_fe_rreq_rdy;
    wire i_fe_wresp_val;
    reg i_fe_rresp_val;
    wire [`PRGA_AXI_ADDR_WIDTH - 1:0] i_fe_wreq_addr, i_fe_rreq_addr;
    wire [`PRGA_BYTES_PER_AXI_DATA - 1:0] i_fe_wreq_strb;
    wire [`PRGA_AXI_DATA_WIDTH - 1:0] i_fe_wreq_data;
    reg [`PRGA_AXI_DATA_WIDTH - 1:0] i_fe_rresp_data;

    pktchain_axilite_intf_fe i_fe (
        .clk                            (clk)
        ,.rst                           (rst_f)
        ,.m_AWVALID                     (m_AWVALID)
        ,.m_AWREADY                     (m_AWREADY)
        ,.m_AWADDR                      (m_AWADDR)
        ,.m_AWPROT                      (m_AWPROT)
        ,.m_WVALID                      (m_WVALID)
        ,.m_WREADY                      (m_WREADY)
        ,.m_WDATA                       (m_WDATA)
        ,.m_WSTRB                       (m_WSTRB)
        ,.m_BVALID                      (m_BVALID)
        ,.m_BREADY                      (m_BREADY)
        ,.m_BRESP                       (m_BRESP)
        ,.m_ARVALID                     (m_ARVALID)
        ,.m_ARREADY                     (m_ARREADY)
        ,.m_ARADDR                      (m_ARADDR)
        ,.m_ARPROT                      (m_ARPROT)
        ,.m_RVALID                      (m_RVALID)
        ,.m_RREADY                      (m_RREADY)
        ,.m_RDATA                       (m_RDATA)
        ,.m_RRESP                       (m_RRESP)
        ,.wreq_val                      (i_fe_wreq_val)
        ,.wreq_rdy                      (i_fe_wreq_rdy)
        ,.wreq_addr                     (i_fe_wreq_addr)
        ,.wreq_strb                     (i_fe_wreq_strb)
        ,.wreq_data                     (i_fe_wreq_data)
        ,.wresp_rdy                     (i_fe_wresp_rdy)
        ,.wresp_val                     (i_fe_wresp_val)
        ,.rreq_val                      (i_fe_rreq_val)
        ,.rreq_rdy                      (i_fe_rreq_rdy)
        ,.rreq_addr                     (i_fe_rreq_addr)
        ,.rresp_rdy                     (i_fe_rresp_rdy)
        ,.rresp_val                     (i_fe_rresp_val)
        ,.rresp_data                    (i_fe_rresp_data)
        );

    // Cross-clock-domain FIFOs
    wire i_cdcq_wreq_full, i_cdcq_wreq_empty, i_cdcq_wreq_rd;
    wire [`PRGA_AXI_DATA_WIDTH + `PRGA_BYTES_PER_AXI_DATA + `PRGA_AXI_ADDR_WIDTH - 1:0] i_cdcq_wreq_din, i_cdcq_wreq_dout;    // {addr, strb, data}
    reg i_cdcq_wreq_wr;

    prga_async_fifo #(
        .DEPTH_LOG2                     (4)
        ,.DATA_WIDTH                    (`PRGA_AXI_DATA_WIDTH + `PRGA_BYTES_PER_AXI_DATA + `PRGA_AXI_ADDR_WIDTH)
        ,.LOOKAHEAD                     (1)
    ) i_cdcq_wreq (
        .wclk                           (clk)
        ,.wrst                          (rst_f)
        ,.full                          (i_cdcq_wreq_full)
        ,.wr                            (i_cdcq_wreq_wr)
        ,.din                           (i_cdcq_wreq_din)
        ,.rclk                          (uclk)
        ,.rrst                          (rst_uclk)
        ,.empty                         (i_cdcq_wreq_empty)
        ,.rd                            (i_cdcq_wreq_rd)
        ,.dout                          (i_cdcq_wreq_dout)
        );

    wire i_cdcq_rreq_full, i_cdcq_rreq_empty, i_cdcq_rreq_rd;
    wire [`PRGA_AXI_ADDR_WIDTH - 1:0] i_cdcq_rreq_din, i_cdcq_rreq_dout;
    reg i_cdcq_rreq_wr;

    prga_async_fifo #(
        .DEPTH_LOG2                     (4)
        ,.DATA_WIDTH                    (`PRGA_AXI_ADDR_WIDTH)
        ,.LOOKAHEAD                     (1)
    ) i_cdcq_rreq (
        .wclk                           (clk)
        ,.wrst                          (rst_f)
        ,.full                          (i_cdcq_rreq_full)
        ,.wr                            (i_cdcq_rreq_wr)
        ,.din                           (i_cdcq_rreq_din)
        ,.rclk                          (uclk)
        ,.rrst                          (rst_uclk)
        ,.empty                         (i_cdcq_rreq_empty)
        ,.rd                            (i_cdcq_rreq_rd)
        ,.dout                          (i_cdcq_rreq_dout)
        );

    wire i_cdcq_rresp_full, i_cdcq_rresp_empty, i_cdcq_rresp_wr;
    wire [`PRGA_AXI_DATA_WIDTH - 1:0] i_cdcq_rresp_din, i_cdcq_rresp_dout;
    reg i_cdcq_rresp_rd;

    prga_async_fifo #(
        .DEPTH_LOG2                     (4)
        ,.DATA_WIDTH                    (`PRGA_AXI_DATA_WIDTH)
        ,.LOOKAHEAD                     (1)
    ) i_cdcq_rresp (
        .wclk                           (uclk)
        ,.wrst                          (rst_uclk)
        ,.full                          (i_cdcq_rresp_full)
        ,.wr                            (i_cdcq_rresp_wr)
        ,.din                           (i_cdcq_rresp_din)
        ,.rclk                          (clk)
        ,.rrst                          (rst_f)
        ,.empty                         (i_cdcq_rresp_empty)
        ,.rd                            (i_cdcq_rresp_rd)
        ,.dout                          (i_cdcq_rresp_dout)
        );

    // User register protection layer
    pktchain_axilite_intf_be_uprot i_uprot (
        .clk                            (uclk)
        ,.rst                           (rst_uclk)
        ,.wreq_empty                    (i_cdcq_wreq_empty)
        ,.wreq_rd                       (i_cdcq_wreq_rd)
        ,.wreq_addr                     (i_cdcq_wreq_dout[`PRGA_AXI_DATA_WIDTH + `PRGA_BYTES_PER_AXI_DATA +: `PRGA_AXI_ADDR_WIDTH])
        ,.wreq_strb                     (i_cdcq_wreq_dout[`PRGA_AXI_DATA_WIDTH +: `PRGA_BYTES_PER_AXI_DATA])
        ,.wreq_data                     (i_cdcq_wreq_dout[0 +: `PRGA_AXI_DATA_WIDTH])
        ,.rreq_empty                    (i_cdcq_rreq_empty)
        ,.rreq_rd                       (i_cdcq_rreq_rd)
        ,.rreq_addr                     (i_cdcq_rreq_dout)
        ,.rresp_full                    (i_cdcq_rresp_full)
        ,.rresp_wr                      (i_cdcq_rresp_wr)
        ,.rresp_data                    (i_cdcq_rresp_din)
        ,.urst_n                        (urst_n)
        ,.u_AWVALID                     (u_AWVALID)
        ,.u_AWREADY                     (u_AWREADY)
        ,.u_AWADDR                      (u_AWADDR)
        ,.u_AWPROT                      (u_AWPROT)
        ,.u_WVALID                      (u_WVALID)
        ,.u_WREADY                      (u_WREADY)
        ,.u_WDATA                       (u_WDATA)
        ,.u_WSTRB                       (u_WSTRB)
        ,.u_BVALID                      (u_BVALID)
        ,.u_BREADY                      (u_BREADY)
        ,.u_BRESP                       (u_BRESP)
        ,.u_ARVALID                     (u_ARVALID)
        ,.u_ARREADY                     (u_ARREADY)
        ,.u_ARADDR                      (u_ARADDR)
        ,.u_ARPROT                      (u_ARPROT)
        ,.u_RVALID                      (u_RVALID)
        ,.u_RREADY                      (u_RREADY)
        ,.u_RDATA                       (u_RDATA)
        ,.u_RRESP                       (u_RRESP)
        );

    // configuration backend
    wire i_cfg_wrdy, i_cfg_programming, i_cfg_success, i_cfg_eq_wr;
    reg i_cfg_wval, i_cfg_eq_full;
    wire [`PRGA_AXI_DATA_WIDTH - 1:0] i_cfg_eq_data;

    pktchain_axilite_intf_be_cfg i_cfg (
        .clk                            (clk)
        ,.rst                           (rst_f || soft_rst)
        ,.wval                          (i_cfg_wval)
        ,.wrdy                          (i_cfg_wrdy)
        ,.wstrb                         (i_fe_wreq_strb)
        ,.wdata                         (i_fe_wreq_data)
        ,.programming                   (i_cfg_programming)
        ,.success                       (i_cfg_success)
        ,.errfifo_full                  (i_cfg_eq_full)
        ,.errfifo_wr                    (i_cfg_eq_wr)
        ,.errfifo_data                  (i_cfg_eq_data)
        ,.cfg_rst                       (cfg_rst)
        ,.cfg_e                         (cfg_e)
        ,.cfg_phit_o_full               (cfg_phit_o_full)
        ,.cfg_phit_o_wr                 (cfg_phit_o_wr)
        ,.cfg_phit_o                    (cfg_phit_o)
        ,.cfg_phit_i_full               (cfg_phit_i_full)
        ,.cfg_phit_i_wr                 (cfg_phit_i_wr)
        ,.cfg_phit_i                    (cfg_phit_i)
        );

    // read response reordering
    localparam  RRESP_TOKEN_DUMMY   = 2'h0,
                RRESP_TOKEN_DATAQ   = 2'h2,
                RRESP_TOKEN_CDCQ    = 2'h3;

    wire i_rresp_tokenq_full, i_rresp_tokenq_empty, i_rresp_dataq_full, i_rresp_dataq_empty;
    reg i_rresp_tokenq_wr, i_rresp_tokenq_rd, i_rresp_dataq_wr, i_rresp_dataq_rd;
    reg [1:0] i_rresp_tokenq_din;
    wire [1:0] i_rresp_tokenq_dout;
    reg [`PRGA_AXI_DATA_WIDTH - 1:0] i_rresp_dataq_din;
    wire [`PRGA_AXI_DATA_WIDTH - 1:0] i_rresp_dataq_dout;

    prga_fifo #(
        .DATA_WIDTH                     (2)
        ,.LOOKAHEAD                     (1)
        ,.DEPTH_LOG2                    (6)
    ) i_rresp_tokenq (
        .clk                            (clk)
        ,.rst                           (rst_f)
        ,.full                          (i_rresp_tokenq_full)
        ,.wr                            (i_rresp_tokenq_wr)
        ,.din                           (i_rresp_tokenq_din)
        ,.empty                         (i_rresp_tokenq_empty)
        ,.rd                            (i_rresp_tokenq_rd)
        ,.dout                          (i_rresp_tokenq_dout)
        );

    prga_fifo #(
        .DATA_WIDTH                     (`PRGA_AXI_DATA_WIDTH)
        ,.LOOKAHEAD                     (1)
        ,.DEPTH_LOG2                    (4)
    ) i_rresp_dataq (
        .clk                            (clk)
        ,.rst                           (rst_f)
        ,.full                          (i_rresp_dataq_full)
        ,.wr                            (i_rresp_dataq_wr)
        ,.din                           (i_rresp_dataq_din)
        ,.empty                         (i_rresp_dataq_empty)
        ,.rd                            (i_rresp_dataq_rd)
        ,.dout                          (i_rresp_dataq_dout)
        );

    always @* begin
        i_fe_rresp_val = 'b0;
        i_fe_rresp_data = {`PRGA_AXI_DATA_WIDTH{1'b0}};
        i_rresp_tokenq_rd = 'b0;
        i_rresp_dataq_rd = 'b0;
        i_cdcq_rresp_rd = 'b0;

        if (~i_rresp_tokenq_empty && i_fe_rresp_rdy) begin
            case (i_rresp_tokenq_dout)
                RRESP_TOKEN_DUMMY: begin
                    i_fe_rresp_val = 'b1;
                    i_rresp_tokenq_rd = 'b1;
                end
                RRESP_TOKEN_DATAQ: begin
                    i_fe_rresp_data = i_rresp_dataq_dout;
                    i_rresp_dataq_rd = 'b1;

                    if (~i_rresp_dataq_empty) begin
                        i_fe_rresp_val = 'b1;
                        i_rresp_tokenq_rd = 'b1;
                    end
                end
                RRESP_TOKEN_CDCQ: begin
                    i_fe_rresp_data = i_cdcq_rresp_dout;
                    i_cdcq_rresp_rd = 'b1;

                    if (~i_cdcq_rresp_empty) begin
                        i_fe_rresp_val = 'b1;
                        i_rresp_tokenq_rd = 'b1;
                    end
                end
            endcase
        end
    end

    // =======================================================================
    // -- Registers ----------------------------------------------------------
    // =======================================================================
    reg [`PRGA_BYTES_PER_AXI_DATA - 1:0] wstrb_aligned;
    reg [`PRGA_AXI_DATA_WIDTH - 1:0] wdata_aligned;

    // Controller State
    reg [`PRGA_CTRL_STATE_WIDTH - 1:0] state;

    always @(posedge clk) begin
        if (rst_f || soft_rst) begin
            state <= `PRGA_CTRL_STATE_RESET;
        end else begin
            case (state)
                `PRGA_CTRL_STATE_RESET: if (i_cfg_programming) begin
                    state <= `PRGA_CTRL_STATE_PROGRAMMING;
                end
                `PRGA_CTRL_STATE_PROGRAMMING: if (~i_cfg_programming) begin
                    if (i_cfg_success) begin
                        state <= `PRGA_CTRL_STATE_APP_READY;
                    end else begin
                        state <= `PRGA_CTRL_STATE_PROG_ERR;
                    end
                end
            endcase
        end
    end

    // Controller config flags
    reg i_ctrl_cfg_wr;
    wire [`PRGA_AXI_DATA_WIDTH - 1:0] ctrl_cfg;

    prga_byteaddressable_reg #(
        .NUM_BYTES                      (`PRGA_BYTES_PER_AXI_DATA)
    ) i_ctrl_cfg (
        .clk                            (clk)
        ,.rst                           (rst_f)
        ,.wr                            (i_ctrl_cfg_wr)
        ,.mask                          (wstrb_aligned)
        ,.din                           (wdata_aligned)
        ,.dout                          (ctrl_cfg)
        );

    // error FIFO
    wire i_errq_full, i_errq_empty;
    reg i_errq_wr, i_errq_rd, i_errq_clr;
    wire [`PRGA_AXI_DATA_WIDTH - 1:0] i_errq_dout;
    reg [`PRGA_AXI_DATA_WIDTH - 1:0] i_errq_din;

    prga_fifo #(
        .DATA_WIDTH                     (`PRGA_AXI_DATA_WIDTH)
        ,.DEPTH_LOG2                    (`PRGA_ERR_FIFO_DEPTH_LOG2)
        ,.LOOKAHEAD                     (1)
    ) i_errq (
        .clk                            (clk)
        ,.rst                           (rst_f || soft_rst || i_errq_clr)
        ,.full                          (i_errq_full)
        ,.wr                            (i_errq_wr)
        ,.din                           (i_errq_din)
        ,.empty                         (i_errq_empty)
        ,.rd                            (i_errq_rd)
        ,.dout                          (i_errq_dout)
        );

    // Bitstream ID
    reg i_bsid_wr;
    wire [`PRGA_AXI_DATA_WIDTH - 1:0] bsid;

    prga_byteaddressable_reg #(
        .NUM_BYTES                      (`PRGA_BYTES_PER_AXI_DATA)
    ) i_bsid (
        .clk                            (clk)
        ,.rst                           (rst_f)
        ,.wr                            (i_bsid_wr)
        ,.mask                          (wstrb_aligned)
        ,.din                           (wdata_aligned)
        ,.dout                          (bsid)
        );

    // Clock divider
    reg [7:0] uclk_div_next;

    always @(posedge clk) begin
        if (rst_f) begin
            uclk_div <= 'b0;
        end else begin
            uclk_div <= uclk_div_next;
        end
    end

    // =======================================================================
    // -- Register Write Pipeline --------------------------------------------
    // =======================================================================
    // Forward declaration of signals
    reg stall_wx, stall_we;

    // execute stage
    localparam  WX_OP_INVAL     = 1'h0,
                WX_OP_ERR       = 1'h1;
    reg [0:0] op_wx;
    reg [`PRGA_AXI_DATA_WIDTH - 1:0] e_wx;

    always @* begin
        stall_wx = 'b0;
        op_wx = WX_OP_INVAL;
        e_wx = {`PRGA_AXI_DATA_WIDTH{1'b0}};

        soft_rst = 'b0;
        wstrb_aligned = i_fe_wreq_strb;
        wdata_aligned = i_fe_wreq_data;
        i_bsid_wr = 'b0;
        i_ctrl_cfg_wr = 'b0;
        i_cfg_wval = 'b0;
        i_errq_clr = 'b0;
        uclk_div_next = uclk_div;
        i_cdcq_wreq_wr = 'b0;

        if (stall_we) begin
            stall_wx = stall_we;
        end else if (i_fe_wreq_val) begin
            if (~i_fe_wresp_rdy) begin
                stall_wx = 'b1;
            end else if (i_fe_wreq_addr[`PRGA_AXI_ADDR_WIDTH - 1:`PRGA_CTRL_ADDR_WIDTH] != `PRGA_CTRL_ADDR_PREFIX) begin
                i_cdcq_wreq_wr = 'b1;
                stall_wx = i_cdcq_wreq_full;
            end else begin
                case (i_fe_wreq_addr[0 +: `PRGA_CTRL_ADDR_WIDTH])
                    `PRGA_CTRL_ADDR_STATE: begin
                        soft_rst = 'b1;
                    end
                    `PRGA_CTRL_ADDR_BITSTREAM_ID,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 1,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 2,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 3,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 4,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 5,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 6,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 7: begin
                        i_bsid_wr = 'b1;
                        wstrb_aligned = i_fe_wreq_strb << (i_fe_wreq_addr - `PRGA_CTRL_ADDR_BITSTREAM_ID);
                        wdata_aligned = i_fe_wreq_data << {(i_fe_wreq_addr - `PRGA_CTRL_ADDR_BITSTREAM_ID), 3'h0};
                    end
                    `PRGA_CTRL_ADDR_BITSTREAM_FIFO: begin
                        i_cfg_wval = 'b1;
                        stall_wx = ~i_cfg_wrdy;
                    end
                    `PRGA_CTRL_ADDR_CONFIG,
                    `PRGA_CTRL_ADDR_CONFIG + 1,
                    `PRGA_CTRL_ADDR_CONFIG + 2,
                    `PRGA_CTRL_ADDR_CONFIG + 3,
                    `PRGA_CTRL_ADDR_CONFIG + 4,
                    `PRGA_CTRL_ADDR_CONFIG + 5,
                    `PRGA_CTRL_ADDR_CONFIG + 6,
                    `PRGA_CTRL_ADDR_CONFIG + 7: begin
                        i_ctrl_cfg_wr = 'b1;
                        wstrb_aligned = i_fe_wreq_strb << (i_fe_wreq_addr - `PRGA_CTRL_ADDR_CONFIG);
                        wdata_aligned = i_fe_wreq_data << {i_fe_wreq_addr - `PRGA_CTRL_ADDR_CONFIG, 3'h0};
                    end
                    `PRGA_CTRL_ADDR_ERR_FIFO: begin
                        i_errq_clr = 'b1;
                    end
                    `PRGA_CTRL_ADDR_UCLK_DIV: begin
                        uclk_div_next = i_fe_wreq_data;
                    end
                    `PRGA_CTRL_ADDR_UREG_TIMEOUT,
                    `PRGA_CTRL_ADDR_URST,
                    `PRGA_CTRL_ADDR_UERR_FIFO: begin
                        i_cdcq_wreq_wr = 'b1;
                        stall_wx = i_cdcq_wreq_full;
                    end
                    default: begin
                        op_wx = WX_OP_ERR;
                        e_wx[`PRGA_ERR_TYPE_INDEX] = `PRGA_ERR_INVAL_WR;
                        e_wx[0 +: `PRGA_AXI_ADDR_WIDTH] = i_fe_wreq_addr;
                    end
                endcase
            end
        end
    end

    assign i_cdcq_wreq_din = {i_fe_wreq_addr, i_fe_wreq_strb, i_fe_wreq_data};
    assign i_fe_wreq_rdy = ~stall_wx;
    assign i_fe_wresp_val = i_fe_wreq_val && ~stall_wx;

    // =======================================================================
    // -- Register Read Pipeline ---------------------------------------------
    // =======================================================================
    // Forward declaration of signals
    //  acquire token, execute,  report error
    reg stall_rt,      stall_rx, stall_re;

    // token-acquiring stage
    reg val_rt;

    always @* begin
        stall_rt = 'b0;
        val_rt = 'b0;

        i_rresp_tokenq_wr = 'b0;
        i_rresp_tokenq_din = 'b0;

        if (stall_rx) begin
            stall_rt = 'b1;
        end else if (i_fe_rreq_val) begin
            val_rt = 'b1;
            i_rresp_tokenq_wr = 'b1;
            stall_rt = i_rresp_tokenq_full;

            if (i_fe_rreq_addr[`PRGA_AXI_ADDR_WIDTH - 1:`PRGA_CTRL_ADDR_WIDTH] != `PRGA_CTRL_ADDR_PREFIX) begin
                i_rresp_tokenq_din = RRESP_TOKEN_CDCQ;
            end else begin
                case (i_fe_rreq_addr[0 +: `PRGA_CTRL_ADDR_WIDTH])
                    `PRGA_CTRL_ADDR_STATE,
                    `PRGA_CTRL_ADDR_CONFIG,
                    `PRGA_CTRL_ADDR_CONFIG + 1,
                    `PRGA_CTRL_ADDR_CONFIG + 2,
                    `PRGA_CTRL_ADDR_CONFIG + 3,
                    `PRGA_CTRL_ADDR_CONFIG + 4,
                    `PRGA_CTRL_ADDR_CONFIG + 5,
                    `PRGA_CTRL_ADDR_CONFIG + 6,
                    `PRGA_CTRL_ADDR_CONFIG + 7,
                    `PRGA_CTRL_ADDR_ERR_FIFO,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 1,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 2,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 3,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 4,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 5,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 6,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 7,
                    `PRGA_CTRL_ADDR_UCLK_DIV: begin
                        i_rresp_tokenq_din = RRESP_TOKEN_DATAQ;
                    end
                    `PRGA_CTRL_ADDR_UREG_TIMEOUT,
                    `PRGA_CTRL_ADDR_UERR_FIFO: begin
                        i_rresp_tokenq_din = RRESP_TOKEN_CDCQ;
                    end
                    default: begin
                        i_rresp_tokenq_din = RRESP_TOKEN_DUMMY;
                    end
                endcase
            end
        end
    end

    assign i_fe_rreq_rdy = ~stall_rt;

    // execute stage
    localparam  RX_OP_INVAL     = 1'b0,
                RX_OP_ERR       = 1'b1;
    reg val_rx;
    reg [`PRGA_AXI_ADDR_WIDTH - 1:0] addr_rx;
    reg [0:0] op_rx;
    reg [`PRGA_AXI_DATA_WIDTH - 1:0] e_rx;

    always @(posedge clk) begin
        if (rst_f) begin
            val_rx <= 'b0;
            addr_rx <= 'b0;
        end else begin
            if (val_rt && ~stall_rt) begin
                val_rx <= 'b1;
                addr_rx <= i_fe_rreq_addr;
            end else if (~stall_rx) begin
                val_rx <= 'b0;
            end
        end
    end

    always @* begin
        stall_rx = 'b0;
        op_rx = RX_OP_INVAL;
        e_rx = {`PRGA_AXI_DATA_WIDTH{1'b0}};

        i_cdcq_rreq_wr = 'b0;
        i_rresp_dataq_wr = 'b0;
        i_rresp_dataq_din = {`PRGA_AXI_DATA_WIDTH{1'b0}};
        i_errq_rd = 'b0;

        if (stall_re) begin
            stall_rx = 'b1;
        end else if (val_rx) begin
            if (addr_rx[`PRGA_AXI_ADDR_WIDTH - 1:`PRGA_CTRL_ADDR_WIDTH] != `PRGA_CTRL_ADDR_PREFIX) begin
                i_cdcq_rreq_wr = 'b1;
                stall_rx = i_cdcq_rreq_full;
            end else begin
                case (addr_rx[0 +: `PRGA_CTRL_ADDR_WIDTH])
                    `PRGA_CTRL_ADDR_STATE: begin
                        stall_rx = i_rresp_dataq_full;
                        i_rresp_dataq_wr = 'b1;
                        i_rresp_dataq_din[0 +: `PRGA_CTRL_STATE_WIDTH] = state;
                    end
                    `PRGA_CTRL_ADDR_CONFIG,
                    `PRGA_CTRL_ADDR_CONFIG + 1,
                    `PRGA_CTRL_ADDR_CONFIG + 2,
                    `PRGA_CTRL_ADDR_CONFIG + 3,
                    `PRGA_CTRL_ADDR_CONFIG + 4,
                    `PRGA_CTRL_ADDR_CONFIG + 5,
                    `PRGA_CTRL_ADDR_CONFIG + 6,
                    `PRGA_CTRL_ADDR_CONFIG + 7: begin
                        stall_rx = i_rresp_dataq_full;
                        i_rresp_dataq_wr = 'b1;
                        i_rresp_dataq_din = ctrl_cfg >> {addr_rx - `PRGA_CTRL_ADDR_CONFIG, 3'h0};
                    end
                    `PRGA_CTRL_ADDR_ERR_FIFO: begin
                        stall_rx = i_rresp_dataq_full;
                        i_rresp_dataq_wr = 'b1;
                        i_errq_rd = ~i_rresp_dataq_full;

                        if (~i_errq_empty) begin
                            i_rresp_dataq_din = i_errq_dout;
                        end
                    end
                    `PRGA_CTRL_ADDR_BITSTREAM_ID,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 1,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 2,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 3,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 4,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 5,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 6,
                    `PRGA_CTRL_ADDR_BITSTREAM_ID + 7: begin
                        stall_rx = i_rresp_dataq_full;
                        i_rresp_dataq_wr = 'b1;
                        i_rresp_dataq_din = bsid >> {addr_rx - `PRGA_CTRL_ADDR_BITSTREAM_ID, 3'h0};
                    end
                    `PRGA_CTRL_ADDR_UCLK_DIV: begin
                        stall_rx = i_rresp_dataq_full;
                        i_rresp_dataq_wr = 'b1;
                        i_rresp_dataq_din[0 +: 8] = uclk_div;
                    end
                    `PRGA_CTRL_ADDR_UREG_TIMEOUT,
                    `PRGA_CTRL_ADDR_UERR_FIFO: begin
                        stall_rx = i_cdcq_rreq_full;
                        i_cdcq_rreq_wr = 'b1;
                    end
                    default: begin
                        op_rx = RX_OP_ERR;
                        e_rx[`PRGA_ERR_TYPE_INDEX] = `PRGA_ERR_INVAL_RD;
                        e_rx[0 +: `PRGA_AXI_ADDR_WIDTH] = addr_rx;
                    end
                endcase
            end
        end
    end

    assign i_cdcq_rreq_din = addr_rx;

    // =======================================================================
    // -- Error Reporting Pipeline -------------------------------------------
    // =======================================================================
    reg [0:0] op_we, op_re;
    reg [`PRGA_AXI_DATA_WIDTH - 1:0] e_we, e_re;

    always @(posedge clk) begin
        if (rst_f) begin
            op_we <= WX_OP_INVAL;
            op_re <= RX_OP_INVAL;
            e_we <= {`PRGA_AXI_DATA_WIDTH{1'b0}};
            e_re <= {`PRGA_AXI_DATA_WIDTH{1'b0}};
        end else begin
            if (~stall_wx) begin
                op_we <= op_wx;
                e_we <= e_wx;
            end else if (~stall_we) begin
                op_we <= WX_OP_INVAL;
            end

            if (~stall_rx) begin
                op_re <= op_rx;
                e_re <= e_rx;
            end else if (~stall_re) begin
                op_re <= RX_OP_INVAL;
            end
        end
    end

    always @* begin
        stall_we = 'b0;
        stall_re = 'b0;

        i_cfg_eq_full = 'b0;
        i_errq_wr = 'b0;
        i_errq_din = {`PRGA_AXI_DATA_WIDTH{1'b0}};

        // Arbitration: configuration backend has first priority on err fifo
        if (i_cfg_eq_wr) begin
            stall_we = op_we == WX_OP_ERR;
            stall_re = op_re == RX_OP_ERR;
            i_errq_wr = 'b1;
            i_errq_din = i_cfg_eq_data;
        end
        // read errors have second priority
        else if (op_re == RX_OP_ERR) begin
            stall_we = op_we == WX_OP_ERR;
            i_errq_wr = 'b1;
            i_errq_din = e_re;
        end
        // write errors have third priorty
        else if (op_we == WX_OP_ERR) begin
            i_errq_wr = 'b1;
            i_errq_din = e_we;
        end
    end

endmodule
