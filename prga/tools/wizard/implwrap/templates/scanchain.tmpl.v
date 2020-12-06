// Automatically generated by PRGA implementation wrapper generator
//
//  Programming circuitry type: 'scanchain'
module implwrap (
    input wire tb_clk
    , input wire tb_rst
    , output reg tb_prog_done
    , input wire [31:0] tb_verbosity
    , input wire [31:0] tb_cycle_cnt
    {%- for name, port in design.ports.items() %}
    , {{ port.direction.case("input", "output") }} wire
        {%- if port.range_ is not none %} [{{ port.range_.stop - port.range_.step }}:{{ port.range_.start }}]{% endif %} {{ name }}
    {%- endfor %}
    );

    // Bitstream stuff
    localparam  BS_NUM_QWORDS       = {{ summary.scanchain.bitstream_size // 64 + (1 if summary.scanchain.bitstream_size % 64 else 0) }},
                BS_WORD_SIZE        = {{ summary.scanchain.chain_width }};

    // Programming protocol
    localparam  INIT            = 3'd0,
                RESET           = 3'd1,
                PROG_WAIT       = 3'd2,
                PROGRAMMING     = 3'd3,
                PROG_STABLIZING = 3'd4,
                PROG_DONE       = 3'd5;

    reg [2:0]                   state;
    reg [31:0]                  wait_cnt;
    reg [63:0]                  bs_data [0:BS_NUM_QWORDS];

    reg                         prog_we, prog_we_prev, prog_we_o_prev;
    wire                        prog_we_o;
    reg [BS_WORD_SIZE-1:0]      prog_din;
    wire [BS_WORD_SIZE-1:0]     prog_dout;
    reg [63:0]                  prog_progress;
    reg [31:0]                  prog_fragments;

    // FPGA instance
    {{ summary.top }} dut (
        .prog_clk(tb_clk)
        ,.prog_rst(tb_rst)
        ,.prog_done(tb_prog_done)
        ,.prog_we(prog_we)
        ,.prog_we_o(prog_we_o)
        ,.prog_din(prog_din)
        ,.prog_dout(prog_dout)
        {%- for port in design.ports.values() %}
            {%- for idx, ((x, y), subtile) in port.iter_io_constraints() %}
        ,.{{- port.direction.case("ipin", "opin") }}_x{{ x }}y{{ y }}_{{ subtile }}({{ port.name }}{%- if idx is not none %}[{{ idx }}]{%- endif %})
            {%- endfor %}
        {%- endfor %}
        );

    // Load bitstream
    initial begin
        tb_prog_done = 1'b0;

        state = INIT;
        wait_cnt = 0;
        prog_we = 1'b0;
        prog_we_prev = 1'b0;
        prog_we_o_prev = 1'b0;
        prog_din = {BS_WORD_SIZE {1'b0} };
        prog_progress = 64'b0;
        prog_fragments = 32'b0;

        if (tb_verbosity > 0)
            $display("[INFO] Bitstream: %s", `BITSTREAM);

        $readmemh(`BITSTREAM, bs_data);
        bs_data[BS_NUM_QWORDS] = 64'b0;
    end

    // Programming FSM
    always @(posedge tb_clk) begin
        if (tb_rst) begin
            state <= RESET;
            prog_progress <= 64'b0;
            wait_cnt <= 0;
            prog_we <= 1'b0;
        end else begin
            case (state)
                RESET: begin
                    state <= PROG_WAIT;
                end
                PROG_WAIT: begin
                    if (wait_cnt == 100) begin
                        state <= PROGRAMMING;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end
                PROGRAMMING: begin
                    if (prog_we) begin
                        if (prog_progress + BS_WORD_SIZE >= BS_NUM_QWORDS * 64) begin
                            if (tb_verbosity > 0)
                                $display("[INFO] [Cycle %04d] Bitstream writing completed", tb_cycle_cnt);
                            prog_we <= 1'b0;
                            state <= PROG_STABLIZING;
                        end else begin
                            prog_we <= {$random} % 100 > 2 ? 1'b1 : 1'b0;   // 2% chance to turn off prog_we
                            prog_progress <= prog_progress + BS_WORD_SIZE;
                        end
                    end else begin
                        prog_we <= {$random} % 100 > 2 ? 1'b1 : 1'b0;   // 2% chance to turn off prog_we
                    end
                end
                PROG_STABLIZING: begin
                    if (prog_fragments == 0) begin
                        if (tb_verbosity > 0)
                            $display("[INFO] [Cycle %04d] Bitstream loading completed", tb_cycle_cnt);
                        state <= PROG_DONE;
                    end
                end
            endcase
        end
    end

    // track "we" toggling
    always @(posedge tb_clk) begin
        if (tb_rst) begin
            prog_we_prev <= 1'b0;
            prog_we_o_prev <= 1'b0;
            prog_fragments <= 32'b0;
        end else begin
            prog_we_prev <= prog_we;
            prog_we_o_prev <= prog_we_o;

            if ((prog_we && ~prog_we_prev) && ~(prog_we_o && ~prog_we_o_prev)) begin
                prog_fragments <= prog_fragments + 1;
            end else if (~(prog_we && ~prog_we_prev) && (prog_we_o && ~prog_we_o_prev)) begin
                prog_fragments <= prog_fragments - 1;
            end
        end
    end

    // Programming data
    always @* begin
        tb_prog_done = state == PROG_DONE;
        prog_din = {bs_data[prog_progress / 64], bs_data[prog_progress / 64 + 1]} >> (128 - BS_WORD_SIZE - prog_progress % 64);
    end

    // Progress tracking
    reg [7:0]   prog_percentage;

    always @(posedge tb_clk) begin
        if (tb_rst) begin
            prog_percentage <= 8'b0;
        end else begin
            if (prog_progress * 100 / BS_NUM_QWORDS / 64 > prog_percentage) begin
                prog_percentage <= prog_percentage + 1;

                if (tb_verbosity > 0)
                    $display("[INFO] Programming progress: %02d%%", prog_percentage + 1);
            end
        end
    end

endmodule
