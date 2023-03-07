# KiCad Makefile - J.Whittington 2023
# -----------------------------------
# Designed to be included by a Makefile within a KiCad project. 
#
# * The parent Makefile MUST define:
# Name of the .kicad_pro, .kicad_pcb and root .kicad_sch
# PROJECT_NAME = my_project
#
# * And SHOULD define:
# Root directory containing $(PROJECT_NAME).kicad_* files
# PROJECT_ROOT = .
# Set to 1 to limit info output
# KICADMK_QUIET = 0
# Can be a string or number indicating release revision
# REVISION = 0
# Append git describe to output zips
# KICADMK_APPEND_GIT = 1
# Don't generate log of variables to include in exports
# KICADMK_INCLUDE_LOG = 0
# Print the log content at start to shell
# KICADMK_PRINT_LOG = 1
#
# * Project generated data will be output to '$(PROJECT_ROOT)/output/X' by default
# * Project distributables and production .zip datapacks will be output to '$(PROJECT_ROOT)/output/dist' and '$(PROJECT_ROOT)/output/prod' by default
override KICADMK_VER = 0.1-aplha

shell_output =
KICADMK_QUIET ?= 0
KICADMK_INCLUDE_LOG ?= 1
ifeq ($(KICADMK_QUIET),0)
	ifeq ($(MAKE_RESTARTS),)
		ifeq ($(MAKELEVEL),0)
			shell_output = $(info $(1))
		endif
	endif
endif

ifndef KICADMK_DIR
	# presume it's the same path to our own file
	KICADMK_DIR := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
endif

# include Common.mk now we know where it is
ifndef COMMON_INCLUDED
	include $(KICADMK_DIR)/Common.mk
endif

## FOLDERS
PROJECT_ROOT ?= .
VPATH = $(PROJECT_ROOT)
# Main output folder for generated files
OUTPUT_FOLDER ?= $(PROJECT_ROOT)/output

# Dist sub-folders
DIST_FOLDER ?= $(OUTPUT_FOLDER)/dist
PROD_FOLDER ?= $(OUTPUT_FOLDER)/prod

# Output sub-folders
SCH_FOLDER = $(OUTPUT_FOLDER)/sch
PCB_FOLDER = $(OUTPUT_FOLDER)/pcb
GERBER_FOLDER = $(OUTPUT_FOLDER)/gerbers
DRILL_FOLDER = $(OUTPUT_FOLDER)/drill
POS_FOLDER = $(OUTPUT_FOLDER)/pos
BOM_FOLDER = $(OUTPUT_FOLDER)/bom
SUB_FOLDERS = $(SCH_FOLDER) $(PCB_FOLDER) $(GERBER_FOLDER) $(DRILL_FOLDER) $(POS_FOLDER) $(BOM_FOLDER)

## CMDS
# Path to kicad-cli
ifndef KICAD_CMD
	ifeq ($(CURRENT_OS),Linux)
		KICAD_CMD = kicad-cli
	else
		KICAD_CMD = /Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli
	endif
endif
ifeq ($(KICAD_CMD),)
	$(error KICAD_CMD cannot be detected and must be defined)
endif
KICAD_VERSION := $(shell $(KICAD_CMD) version)
BOM_CMD ?= kibom
BOM_CMD_FLAGS +=

GREP ?= grep
RM = rm -rf
MV = mv
CAT = cat
ECHO = printf
MKDIR = mkdir -p
ZIP = zip

# LAYERS

PCB_DRAWING_LAYERS ?= "F.Cu,B.Cu,Edge.Cuts,Dwgs.User"
DXF_LAYERS ?= "Edge.Cuts,Dwgs.User,Cmts.User,Eco1.User,Eco2.User,F.Fab,B.Fab"
# GERBER_LAYERS = "F.Cu,B.Cu" # can be defined

## FLAGS
# kicad-cli command flags
# PDF_FLAGS +=
# SVG_FLAGS +=
# STEP_FLAGS +=
# PYTHON_BOM_FLAGS +=
# GERBER_FLAGS +=
# DRILL_FLAGS +=
# POS_FLAGS +=
DXF_FLAGS += --layers $(DXF_LAYERS)
PCB_PDF_FLAGS += --layers $(PCB_DRAWING_LAYERS)
PCB_SVG_FLAGS += --layers $(PCB_DRAWING_LAYERS)
# flags for zip archives
ZIP_FLAGS += -x \*.zip -x \*.ini -x \*.xml

ifneq ($(call dir_if_exists,$(PROJECT_ROOT)/.git),)
		GIT_DESCRIBE := $(call git_tag_ver)
endif

## FILES
BOM_FILENAME ?= $(PROJECT_NAME).csv
DRILL_FILENAMES ?= $(PROJECT_NAME).drl
POS_FILENAMES ?= $(PROJECT_NAME)-both.pos $(PROJECT_NAME)-top.pos $(PROJECT_NAME)-bottom.pos

ifneq ($(REVISION),)
DIST_BASE_FILENAME ?= $(PROJECT_NAME)-$(REVISION)
PROD_BASE_FILENAME ?= $(PROJECT_NAME)-$(REVISION)
else
DIST_BASE_FILENAME ?= $(PROJECT_NAME)
PROD_BASE_FILENAME ?= $(PROJECT_NAME)
endif

ifeq ($(KICADMK_APPEND_GIT),1)
	ifneq ($(GIT_DESCRIBE),)
		DIST_BASE_FILENAME := $(DIST_BASE_FILENAME)-$(GIT_DESCRIBE)
		PROD_BASE_FILENAME := $(PROD_BASE_FILENAME)-$(GIT_DESCRIBE)
	endif
endif

ifeq ($(KICADMK_INCLUDE_LOG),1)
	LOG_FILE = $(OUTPUT_FOLDER)/$(DIST_BASE_FILENAME)-job.log
endif

# if gerber layers defined, generate based on these
ifdef GERBER_LAYERS
	# GERBER_LAYERS_SPLIT = $(shell echo $(GERBER_LAYERS) | sed 's/,/ /g')
	# TODO match layers to extension so target matches and is not re-built
	# GERBER_FILES := $(foreach layer,$(GERBER_LAYERS_SPLIT),$(GERBER_FOLDER)/$(PROJECT_NAME)-$(subst .,_,$(layer)).gbr)
	# GERBER_TARGET_FILES := $(GERBER_FILES)
	# for now only layers specified via flag will be built
	GERBER_FILES = $(wildcard $(GERBER_FOLDER)/*.g*)
	GERBER_TARGET_FILES = $(GERBER_FOLDER)/$(PROJECT_NAME)-job.gbrjob $(LOG_FILE)
	GERBER_FLAGS += --layers $(GERBER_LAYERS)
# else just use the job target to make all
else
	# recursively expanded once gerbers built
	GERBER_FILES = $(wildcard $(GERBER_FOLDER)/*.g*)
	GERBER_TARGET_FILES = $(GERBER_FOLDER)/$(PROJECT_NAME)-job.gbrjob $(LOG_FILE)
endif

BOM_FILE = $(BOM_FOLDER)/$(BOM_FILENAME) $(LOG_FILE)
DRILL_FILES = $(foreach filename,$(DRILL_FILENAMES),$(DRILL_FOLDER)/$(filename)) $(LOG_FILE)
POS_FILES = $(foreach filename,$(POS_FILENAMES),$(POS_FOLDER)/$(filename)) $(LOG_FILE)

DIST_ZIP_FILE_NAME = $(DIST_BASE_FILENAME).zip
PRODUCTION_ALL_ZIP_FILE_NAME = $(PROD_BASE_FILENAME)-prod.zip

# includes drill files as manufactureres will require this
PRODUCTION_GERBER_ZIP_FILES = $(GERBER_FILES) $(wildcard $(DRILL_FOLDER)/*.drl $(DRILL_FOLDER)/*_map*) $(LOG_FILE)
PRODUCTION_GERBER_ZIP_FILE_NAME = $(PROD_BASE_FILENAME)-gerber.zip

PRODUCTION_POS_ZIP_FILE_NAME = $(PROD_BASE_FILENAME)-pos.zip

PRODUCTION_BOM_ZIP_FILE_NAME = $(PROD_BASE_FILENAME)-bom.zip

MECH_FILES = $(PCB_FOLDER)/$(PROJECT_NAME).step $(PCB_FOLDER)/$(PROJECT_NAME).dxf $(LOG_FILE)
MECH_ZIP_FILE_NAME = $(DIST_BASE_FILENAME)-mech.zip

SCH_FILES = $(SCH_FOLDER)/$(PROJECT_NAME).pdf $(SCH_FOLDER)/$(PROJECT_NAME).svg $(SCH_FOLDER)/$(PROJECT_NAME).net $(LOG_FILE)
SCH_ZIP_FILE_NAME = $(DIST_BASE_FILENAME)-sch.zip

PCB_FILES = $(MECH_FILES) $(PCB_FOLDER)/$(PROJECT_NAME).pdf $(PCB_FOLDER)/$(PROJECT_NAME).svg $(LOG_FILE)
PCB_ZIP_FILE_NAME = $(DIST_BASE_FILENAME)-pcb.zip

REF_FILES = $(SCH_FILES) $(PCB_FILES)
REF_ZIP_FILE_NAME = $(DIST_BASE_FILENAME)-ref.zip

LOG_HEADER = Files generated with KiCad Makefile $(KICADMK_VER) on $(shell date) for $(PROJECT_NAME)
define LOG_CONTENT 
# Configuration
$(call config_variable,CURRENT_OS,-,1)
$(call config_variable,REVISION,-,1)
$(call config_variable,GIT_DESCRIBE,-,1)
$(call config_variable,KICAD_CMD,-,1)
$(call config_variable,KICAD_VERSION,-,1)
## BoM
$(call config_variable,BOM_CMD,-,1)
$(call config_variable,BOM_CMD_FLAGS,-,1)
$(call config_variable,BOM_FILENAME,-,1)
$(call config_variable,PYTHON_BOM_FLAGS,-,1)
## SCH
$(call config_variable,PDF_FLAGS,-,1)
$(call config_variable,SVG_FLAGS,-,1)
## PCB
$(call config_variable,PCB_DRAWING_LAYERS,-,1)
$(call config_variable,DXF_LAYERS,-,1)
$(call config_variable,DXF_FLAGS,-,1)
$(call config_variable,PDF_LAYERS,-,1)
$(call config_variable,PCB_PDF_FLAGS,-,1)
$(call config_variable,SVG_LAYERS,-,1)
$(call config_variable,PCB_SVG_FLAGS,-,1)
## Production
$(call config_variable,STEP_FLAGS,-,1)
$(call config_variable,GERBER_TARGET_FILES,-,1)
$(call config_variable,GERBER_FLAGS,-,1)
$(call config_variable,DRILL_FILENAMES,-,1)
$(call config_variable,DRILL_FLAGS,-,1)
$(call config_variable,POS_FILENAMES,-,1)
$(call config_variable,POS_FLAGS,-,1)
## Misc
$(call config_variable,ZIP_FLAGS,-,1)
endef

$(call shell_output,Running KiCad Makefile $(KICADMK_VER) for $(PROJECT_NAME) $(REVISION):$(GIT_DESCRIBE))
$(call show_separator)
ifeq ($(KICADMK_PRINT_LOG),1)
	$(call shell_output,$(subst $(newline),\n\,$(LOG_CONTENT)))
endif

.PHONY: all clean clean-dist clean-prod prod prod-gerber prod-pos prod-bom dist dist-mech dist-sch dist-pcb dist-ref gerbers pos bom sch pcb drill mech

all: prod dist

dist: $(DIST_FOLDER)/$(DIST_ZIP_FILE_NAME)
dist-mech: $(DIST_FOLDER)/$(MECH_ZIP_FILE_NAME)
dist-sch: $(DIST_FOLDER)/$(SCH_ZIP_FILE_NAME)
dist-pcb: $(DIST_FOLDER)/$(PCB_ZIP_FILE_NAME)
dist-ref: $(DIST_FOLDER)/$(REF_ZIP_FILE_NAME)

prod: $(PROD_FOLDER)/$(PRODUCTION_ALL_ZIP_FILE_NAME)
prod-gerbers: $(PROD_FOLDER)/$(PRODUCTION_GERBER_ZIP_FILE_NAME)
prod-pos: $(PROD_FOLDER)/$(PRODUCTION_POS_ZIP_FILE_NAME)
prod-bom: $(PROD_FOLDER)/$(PRODUCTION_BOM_ZIP_FILE_NAME)

bom: $(BOM_FILE)
sch: $(SCH_FILES)
pcb: $(PCB_FILES)
drill: $(DRILL_FILES)
pos: $(POS_FILES)
mech: $(MECH_FILES)
net: $(SCH_FOLDER)/$(PROJECT_NAME).net
gerbers: $(GERBER_TARGET_FILES) | $(GERBER_FOLDER)

clean:
	$(RM) $(OUTPUT_FOLDER)

clean-dist:
	$(RM) $(DIST_FOLDER)

clean-prod:
	$(RM) $(PROD_FOLDER)

$(BOM_FOLDER)/%.xml: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_sch | $(BOM_FOLDER)
	$(KICAD_CMD) sch export python-bom $(PYTHON_BOM_FLAGS) -o $@ $<

$(BOM_FOLDER)/%.csv: $(BOM_FOLDER)/%.xml | $(BOM_FOLDER)
	$(BOM_CMD) $(BOM_CMD_FLAGS) $< $@ 

$(SCH_FOLDER)/%.net: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_sch | $(SCH_FOLDER)
	$(KICAD_CMD) sch export netlist -o $@ $<

$(SCH_FOLDER)/%.pdf: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_sch | $(SCH_FOLDER)
	$(KICAD_CMD) sch export pdf $(PDF_FLAGS) -o $@ $<

$(SCH_FOLDER)/%.svg: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_sch | $(SCH_FOLDER)
	$(KICAD_CMD) sch export svg $(STEP_FLAGS) -o '$(@D)' $<

$(PCB_FOLDER)/%.step: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(PCB_FOLDER)
	$(KICAD_CMD) pcb export step -o $@ $< 

$(PCB_FOLDER)/%.pdf: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(PCB_FOLDER)
	$(KICAD_CMD) pcb export pdf $(PCB_PDF_FLAGS) -o $@ $<

$(PCB_FOLDER)/%.svg: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(PCB_FOLDER)
	$(KICAD_CMD) pcb export svg $(PCB_SVG_FLAGS) -o $@ $<

$(PCB_FOLDER)/%.dxf: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(PCB_FOLDER)
	$(KICAD_CMD) pcb export dxf $(DXF_FLAGS) -o $@ $<

# non-specific target to use layers
# $(GERBER_FOLDER)/.gerbers: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(GERBER_FOLDER)
# 	$(KICAD_CMD) pcb export gerbers $(GERBER_FLAGS) -o '$(@D)' $< 
# 	touch $@

# gerbers plural sub-command will output gbrjob file
$(GERBER_FOLDER)/%-job.gbrjob: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(GERBER_FOLDER)
	$(KICAD_CMD) pcb export gerbers $(GERBER_FLAGS) -o '$(@D)' $< 

# extract the layer from the target gerber filename
%.gtl %.gbl %.gta %.gtb %.gto %.gbo %.gts %.gbs %.gbr %.gm1 %.gm2 %.gm3 %.gko %.gg1 %.gd1 %.g2 %.g3 %.g4 %.g5 %.g6 %.g7: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb
	$(KICAD_CMD) pcb export gerber $(GERBER_FLAGS) --layers $(basename $(shell echo ‘$(@F)’ | $(GREP) -Eo "(\w+?_\w+?)\.\w+" | sed 's/_/./g')) -o $@ $< 

$(DRILL_FOLDER)/%-PTH.drl $(DRILL_FOLDER)/%-NPTH.drl: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(DRILL_FOLDER)
	$(KICAD_CMD) pcb export drill $(DRILL_FLAGS) --separate-files --excellon-separate-th -o '$(@D)'/ $< 

$(DRILL_FOLDER)/%.drl: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(DRILL_FOLDER)
	$(KICAD_CMD) pcb export drill $(DRILL_FLAGS) -o  '$(@D)'/ $< 

$(POS_FOLDER)/%-top.pos: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(POS_FOLDER)
	$(KICAD_CMD) pcb export pos --side "front" $(POS_FLAGS) -o $@ $< 

$(POS_FOLDER)/%-bottom.pos: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(POS_FOLDER)
	$(KICAD_CMD) pcb export pos --side "back" $(POS_FLAGS) -o $@ $< 

$(POS_FOLDER)/%.pos: $(PROJECT_ROOT)/$(PROJECT_NAME).kicad_pcb | $(POS_FOLDER)
	$(KICAD_CMD) pcb export pos $(POS_FLAGS) -o $@ $< 

$(PROD_FOLDER)/$(PRODUCTION_BOM_ZIP_FILE_NAME): $(BOM_FILE) | $(PROD_FOLDER)
	$(ZIP) $(ZIP_FLAGS) -j $@ $?

$(PROD_FOLDER)/$(PRODUCTION_GERBER_ZIP_FILE_NAME): $(GERBER_TARGET_FILES) $(DRILL_FILES) | $(PROD_FOLDER)
	$(ZIP) $(ZIP_FLAGS) -j $@ $(PRODUCTION_GERBER_ZIP_FILES)

$(PROD_FOLDER)/$(PRODUCTION_POS_ZIP_FILE_NAME): $(POS_FILES) | $(PROD_FOLDER)
	$(ZIP) $(ZIP_FLAGS) -j $@ $?

$(PROD_FOLDER)/$(PRODUCTION_ALL_ZIP_FILE_NAME): $(BOM_FILE) $(DRILL_FILES) $(POS_FILES) $(GERBER_TARGET_FILES) | $(PROD_FOLDER)
	$(ZIP) $@ $(BOM_FOLDER)/*.csv $(DRILL_FOLDER)/* $(POS_FOLDER)/* $(GERBER_FOLDER)/* $(ZIP_FLAGS)

$(DIST_FOLDER)/$(MECH_ZIP_FILE_NAME): $(MECH_FILES) | $(DIST_FOLDER)
	$(ZIP) $(ZIP_FLAGS) -j $@ $?

$(DIST_FOLDER)/$(SCH_ZIP_FILE_NAME): $(SCH_FILES) | $(DIST_FOLDER)
	$(ZIP) $(ZIP_FLAGS) -j $@ $?

$(DIST_FOLDER)/$(PCB_ZIP_FILE_NAME): $(PCB_FILES) | $(DIST_FOLDER)
	$(ZIP) $(ZIP_FLAGS) -j $@ $?

$(DIST_FOLDER)/$(REF_ZIP_FILE_NAME): $(REF_FILES) | $(DIST_FOLDER)
	$(ZIP) $(ZIP_FLAGS) -j $@ $?

$(DIST_FOLDER)/$(DIST_ZIP_FILE_NAME): $(BOM_FILE) $(DRILL_FILES) $(POS_FILES) $(GERBER_TARGET_FILES) $(PCB_FILES) $(SCH_FILES) | $(DIST_FOLDER)
	$(ZIP) $@ -r $(OUTPUT_FOLDER) $(ZIP_FLAGS)

$(OUTPUT_FOLDER):
	$(MKDIR) $@

ifneq ($(OUTPUT_FOLDER),$(DIST_FOLDER))
$(DIST_FOLDER):
	$(MKDIR) $@
endif

ifneq ($(OUTPUT_FOLDER),$(PROD_FOLDER))
$(PROD_FOLDER):
	$(MKDIR) $@
endif

$(SUB_FOLDERS): | $(OUTPUT_FOLDER)
	$(MKDIR) $@

%.log: export LOG_CONTENT:=$(LOG_HEADER)\n\n$(LOG_CONTENT)
%.log:
	@$(ECHO) "$${LOG_CONTENT}" > $@
