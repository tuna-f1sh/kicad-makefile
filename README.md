A Makefile for KiCad 7.0+. It leverages the new `kicad-cli` command included in 7.0 to generate output data for distribution and production.

# Usage

1. Clone this repository somewhere and define an environment variable `KICADMK_DIR` to the folder:
`export KICADMK_DIR=/home/me/kicad-makefile`
2. Copy the example Makefile 'Makefile.example' to the KiCad project to build:
`cp Makefile.example /home/me/my_project`
3. Edit the example Makefile referring to comments as a guide.
4. Run `make` to run default target that builds output, a merged sch and pcb .pdf and a distribution and production .zip:
* ./output/my_project.pdf: merged pdf with sch pages and pcb copper layers.
* ./output/dist/my_project.zip: sch renders, pcb renders, bom, gerbers, pos and drill files.
* ./output/prod/my_project-prod.zip: bom, gerbers, pos and drill files.

Refer to 'Kicad.mk' for other targets.

The project is alpha status and also consider that the `kicad-cli` command is at an early stage; things might change!

## Extra Setup

* BoM: [KiBOM](https://github.com/SchrodingersGat/KiBoM) by default, requires install either with `pip` or path to repository - see [Makefile.example](https://github.com/tuna-f1sh/kicad-makefile/blob/main/Makefile.example) and './bin/kibom'. Can be defined with `BOM_CMD` and `BOM_CMD_FLAGS`. Note that by default, the KiBOM script appends to target output so will be re-built whenever `BOM_FILE` is a prerequisite. One can fix this by supplying a 'bom.ini' with `output_file_name = %O`.

## Container

A target to build a docker container is available `make image`. One can then run make within the KiCad project folder with:

`docker run --rm -v "$(pwd)":/project kicad-makefile:latest make`

The project also publish a [package](https://github.com/tuna-f1sh/kicad-makefile/pkgs/container/kicad-makefile):

`docker pull ghcr.io/tuna-f1sh/kicad-makefile:latest`

## Integration with CI/CD

See my [entree projec](https://github.com/tuna-f1sh/entree/actions) as an example of how to use this to build outputs for release etc.

## Useful Variables

Defaults shown, can be set in Makefile or environment. Refer to [Makefile.example](https://github.com/tuna-f1sh/kicad-makefile/blob/main/Makefile.example) for others.

```
# Main output folder for generated files
OUTPUT_FOLDER ?= $(PROJECT_ROOT)/output

# Dist sub-folders
DIST_FOLDER ?= $(OUTPUT_FOLDER)/dist
PROD_FOLDER ?= $(OUTPUT_FOLDER)/prod
```
