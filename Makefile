PROJ_PATH = $(shell pwd)

DESIGN ?= gcd
SDC_FILE ?= $(PROJ_PATH)/example/gcd.sdc
RTL_FILES ?= $(shell find $(PROJ_PATH)/example -name "*.v")
export CLK_FREQ_MHZ ?= 500

RESULT_DIR = $(PROJ_PATH)/result/$(DESIGN)-$(CLK_FREQ_MHZ)MHz
NETLIST_V  = $(RESULT_DIR)/$(DESIGN).netlist.v
TIMING_RPT = $(RESULT_DIR)/$(DESIGN).rpt

MERGED_LIB = $(PROJ_PATH)/nangate45/lib/merged.lib
init: $(MERGED_LIB)
$(MERGED_LIB):
	cd $(@D) && $(PROJ_PATH)/init/mergeLib.pl nangate45_merged `ls *.lib | grep -v merged` > $@.tmp
	cd $(@D) && $(PROJ_PATH)/init/removeDontUse.pl $@.tmp "TAPCELL_X1 FILLCELL_X1 AOI211_X1 OAI211_X1" > $@
	rm $@.tmp

syn: $(NETLIST_V)
$(NETLIST_V): $(RTL_FILES) yosys.tcl
	mkdir -p $(@D)
	echo tcl yosys.tcl $(DESIGN) \"$(RTL_FILES)\" $(NETLIST_V) | yosys -l $(@D)/yosys.log -s -

sta: $(TIMING_RPT)
$(TIMING_RPT): $(SDC_FILE) $(NETLIST_V)
	cd bin && LD_LIBRARY_PATH=lib/ ./iSTA $(PROJ_PATH)/sta.tcl $(DESIGN) $(SDC_FILE) $(NETLIST_V)

clean:
	-rm -rf result/

.PHONY: init syn sta clean
