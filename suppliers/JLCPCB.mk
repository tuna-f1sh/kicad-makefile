# ref: https://jlcpcb.com/help/article/how-to-generate-gerber-and-drill-files-in-kicad-9
GERBER_FLAGS =
DRILL_FLAGS = --excellon-zeros-format=suppressleading --map-format=ps --excellon-min-header --generate-map --excellon-oval-format=alternate
DRILL_FILENAMES = $(PROJECT_NAME)-PTH.drl $(PROJECT_NAME)-NPTH.drl

# ref: https://jlcpcb.com/help/article/How-to-generate-the-BOM-and-Centroid-file-from-KiCAD
POS_FLAGS = --units=mm
POS_FILENAMES = $(PROJECT_NAME)-both-jlcpcb.csv

PROD_FOLDER ?= $(OUTPUT_FOLDER)/prod-jlcpcb

# PCB takes separate zips
prod: 
	$(MAKE) prod-all
