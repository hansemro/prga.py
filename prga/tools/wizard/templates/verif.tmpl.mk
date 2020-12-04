# Automatically generated by PRGA Verification Flow Generator
{%- macro input_vars(prefix, config) %}
{{ prefix }}_SRCS :=
{%- for src in config.sources %}
{{ prefix }}_SRCS += {{ abspath(src) }}
{%- endfor %}

{{ prefix }}_INCDIRS :=
{%- for dir_ in config.includes|default([]) %}
{{ prefix }}_INCDIRS += {{ abspath(dir_) }}
{%- endfor %}

{{ prefix }}_COMP_FLAGS := $(addprefix $(INCPREFIX),$({{ prefix }}_INCDIRS))
{%- for k, v in (config.defines|default({})).items() %}
	{%- if none(v) %}
{{ prefix }}_COMP_FLAGS += $(DEFPREFIX){{ k }}
	{%- else %}
{{ prefix }}_COMP_FLAGS += $(DEFPREFIX){{ k }}={{ v }}
	{%- endif %}
{%- endfor %}

{{ prefix }}_INCS := $(foreach d,$({{ prefix }}_INCDIRS),$(shell find $d -type f))
{%- endmacro %}
# ----------------------------------------------------------------------------
# -- Options -----------------------------------------------------------------
# ----------------------------------------------------------------------------
GUI ?=

# ----------------------------------------------------------------------------
# -- Binaries ----------------------------------------------------------------
# ----------------------------------------------------------------------------
# Use `make PYTHON=xxx` to replace these binaries if needed
PYTHON ?= python
COMP ?= {{ compiler }}

# ----------------------------------------------------------------------------
# -- Compiler Options --------------------------------------------------------
# ----------------------------------------------------------------------------
{%- if compiler == 'iverilog' %}
COMP_FLAGS := -g2005
RUN_FLAGS :=
INCPREFIX := -I
DEFPREFIX := -D
{%- elif compiler == 'vcs' %}
COMP_FLAGS := -v2005
RUN_FLAGS :=
INCPREFIX := +incdir+
DEFPREFIX := +define+

ifneq ($(GUI),)
COMP_FLAGS += -debug_all
RUN_FLAGS += -gui
endif
{%- else %}
# Makefile generated with unsupported compiler: {{ compiler }}
{%- endif %}

# ----------------------------------------------------------------------------
# -- Make Config -------------------------------------------------------------
# ----------------------------------------------------------------------------
SHELL = /bin/bash
.SHELLFLAGS = -o pipefail -c

# ----------------------------------------------------------------------------
# -- Inputs ------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ** Configuration File **
CONFIG := {{ config }}

# ** Verilog-to-Bitstream Project Directory **
V2B_DIR := {{ abspath(v2b_dir) }}

# ** Target Design **
DESIGN := {{ design.name }}

# ** Test **
TEST := {{ test_name }}
{{- input_vars("TEST", test) }}

# ** Behavioral Model **
{{- input_vars("BEHAV", design) }}

# ** Post-Synthesis Model **
{{- input_vars("LIB", libs) }}

POSTSYN_SRCS := $(V2B_DIR)/postsyn.v

# ** FPGA (Post-Implementation Model) **
{{- input_vars("FPGA", fpga) }}

# ** Implementation Wrapper **
IMPLWRAP_V := $(V2B_DIR)/implwrap.v

# ** Bitstream **
BITSTREAM := $(V2B_DIR)/bitgen.out

# ----------------------------------------------------------------------------
# -- Outputs -----------------------------------------------------------------
# ----------------------------------------------------------------------------
# ** Testbench **
TB_SRCS := tb.v

# ** Behavioral Simulation **
BEHAV_SIM := behav.simv
BEHAV_SIM_LOG := behav.log

# ** Post-Synthesis Simulation
POSTSYN_SIM := postsyn.simv
POSTSYN_SIM_LOG := postsyn.log

# ** Post-Implementation Simulation
POSTIMPL_SIM := postimpl.simv
POSTIMPL_SIM_LOG := postimpl.log

# ** Junks to Remove **
JUNKS :=
JUNKS += $(TB_SRCS)
JUNKS += $(BEHAV_SIM) $(BEHAV_SIM_LOG)
JUNKS += $(POSTSYN_SIM) $(POSTSYN_SIM_LOG)
JUNKS += $(POSTIMPL_SIM) $(POSTIMPL_SIM_LOG)
JUNKS += *.daidir csrc ucli.key

# ----------------------------------------------------------------------------
# -- Phony rules -------------------------------------------------------------
# ----------------------------------------------------------------------------
.PHONY: tb postimpl behav postsyn clean makefile_validation_

postimpl: $(POSTIMPL_SIM_LOG) makefile_validation_

tb: $(TB_SRCS) makefile_validation_

behav: $(BEHAV_SIM_LOG) makefile_validation_

postsyn: $(POSTSYN_SIM_LOG) makefile_validation_

clean:
	rm -rf $(JUNKS)

makefile_validation_:
ifndef COMP
	echo "Verilog compiler not specified. This generated Makefile is invalid"
	exit 1
endif

# ----------------------------------------------------------------------------
# -- Regular rules -----------------------------------------------------------
# ----------------------------------------------------------------------------
$(BEHAV_SIM_LOG): $(BEHAV_SIM)
	./$< $(RUN_FLAGS) | tee $@

$(BEHAV_SIM): $(TB_SRCS) $(TEST_SRCS) $(TEST_INCS) $(BEHAV_SRCS) $(BEHAV_INCS)
	$(COMP) $(COMP_FLAGS) $(TB_COMP_FLAGS) $(TB_SRCS) \
		$(TEST_COMP_FLAGS) $(addprefix -v ,$(TEST_SRCS)) \
		$(BEHAV_COMP_FLAGS) $(addprefix -v ,$(BEHAV_SRCS)) \
		-o $@

$(POSTSYN_SIM_LOG): $(POSTSYN_SIM)
	./$< $(RUN_FLAGS) | tee $@

$(POSTSYN_SIM): $(TB_SRCS) $(TEST_SRCS) $(TEST_INCS) $(BEHAV_SRCS) $(BEHAV_INCS) $(LIB_SRCS) $(LIB_INCS) $(POSTSYN_SRCS)
	$(COMP) $(COMP_FLAGS) $(DEFPREFIX)PRGA_TEST_POSTSYN $(TB_COMP_FLAGS) $(TB_SRCS) \
		$(TEST_COMP_FLAGS) $(addprefix -v ,$(TEST_SRCS)) \
		$(BEHAV_COMP_FLAGS) $(addprefix -v ,$(BEHAV_SRCS)) \
		$(LIB_COMP_FLAGS) $(addprefix -v ,$(LIB_SRCS)) $(addprefix -v ,$(POSTSYN_SRCS)) \
		-o $@

$(POSTIMPL_SIM_LOG): $(POSTIMPL_SIM)
	./$< $(RUN_FLAGS) | tee $@

$(POSTIMPL_SIM): $(TB_SRCS) $(TEST_SRCS) $(TEST_INCS) $(BEHAV_SRCS) $(BEHAV_INCS) $(LIB_SRCS) $(LIB_INCS) $(POSTSYN_SRCS) $(FPGA_SRCS) $(FPGA_INCS) $(IMPLWRAP_V) $(BITSTREAM)
	$(COMP) $(COMP_FLAGS) $(DEFPREFIX)PRGA_TEST_POSTIMPL $(TB_COMP_FLAGS) $(TB_SRCS) \
		$(TEST_COMP_FLAGS) $(addprefix -v ,$(TEST_SRCS)) \
		$(BEHAV_COMP_FLAGS) $(addprefix -v ,$(BEHAV_SRCS)) \
		$(LIB_COMP_FLAGS) $(addprefix -v ,$(LIB_SRCS)) $(addprefix -v ,$(POSTSYN_SRCS)) \
		$(FPGA_COMP_FLAGS) $(addprefix -v ,$(FPGA_SRCS)) \
		$(DEFPREFIX)BITSTREAM='"$(shell realpath $(BITSTREAM))"' $(INCPREFIX)$(V2B_DIR) -v $(IMPLWRAP_V) \
		-o $@

$(TB_SRCS): $(POSTSYN_SRCS)
	$(PYTHON) -m prga.tools.wizard.verif testbench $(CONFIG) $(V2B_DIR) -t {{ test_name }}

$(POSTSYN_SRCS):
	$(MAKE) -C $(V2B_DIR) syn

$(IMPLWRAP_V):
	$(MAKE) -C $(V2B_DIR) implwrap

$(BITSTREAM):
	$(MAKE) -C $(V2B_DIR) bitgen
