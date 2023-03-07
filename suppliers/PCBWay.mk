# ref: https://www.pcbway.com/blog/help_center/Generate_Gerber_file_from_Kicad_5_1_6.html
GERBER_FLAGS = --no-x2
DRILL_FLAGS = --excellon-zeros-format=suppressleading --map-format=ps --excellon-min-header --generate-map
DRILL_FILENAMES = $(PROJECT_NAME)-PTH.drl $(PROJECT_NAME)-NPTH.drl

# ref: https://www.pcbway.com/blog/help_center/Generate_Position_File_in_Kicad.html
POS_FLAGS = --format=ascii --units=mm
POS_FILENAMES = $(PROJECT_NAME)-both.pos

PROD_FOLDER ?= $(OUTPUT_FOLDER)/prod-pcbway
