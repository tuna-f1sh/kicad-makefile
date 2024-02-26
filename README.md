A Makefile for KiCad 7.0 -> projects. It leverages the new `kicad-cli` command included in 7.0 -> to generate output data for distribution and production. Designed to be used locally and in CI/CD pipelines. With the addition of ERC/DRC checks in KiCad 8.0, it can be used to pass/fail builds based on these checks.

# Usage

1. Clone this repository somewhere and define an environment variable `KICADMK_DIR` to the folder:
`export KICADMK_DIR=/home/me/kicad-makefile`
2. Copy the example Makefile 'Makefile.example' to the KiCad project to build:
`cp Makefile.example /home/me/my_project/Makefile`
3. Edit the example Makefile referring to comments as a guide.
4. Run `make` to run default target that builds output, a merged sch and pcb .pdf and a distribution and production .zip:
* ./output/my_project.pdf: merged pdf with sch pages and pcb copper layers.
* ./output/dist/my_project.zip: sch renders, pcb renders, bom, gerbers, pos and drill files.
* ./output/prod/my_project-prod.zip: bom, gerbers, pos and drill files.

Refer to 'Kicad.mk' for other targets.

The project is fairly stable at this point consider that the `kicad-cli` command is at an early stage; things might change!

## Container

A target to build a docker container is available `make image`. One can then run make within the KiCad project folder with:

`docker run --rm -v "$(pwd)":/project kicad-makefile:latest make`

The project also publish a [package](https://github.com/tuna-f1sh/kicad-makefile/pkgs/container/kicad-makefile):

`docker pull ghcr.io/tuna-f1sh/kicad-makefile:latest`

The image uses the latest major KiCad release. For previous releases:

* 7.0 [tag `v1.0`]: `ghcr.io/tuna-f1sh/kicad-makefile:v1.0`

## Integration with CI/CD

See my [entree project](https://github.com/tuna-f1sh/entree/actions) as an example of how to use this to build outputs for release etc.

Use the environment variable `EXIT_CODE_VIOLATIONS=1` to fail the build on ERC/DRC violations. The rules are checked as part of the `sch` and `pcb` targets. To just check rules with exit code, use `EXIT_CODE_VIOLATIONS=1 make rules` Alternatively, the to the `SCH_ERC_FLAGS` and `PCB_DRC_FLAGS` `--exit-code-violations`

## Extra Setup

These steps are optional and can be skipped if the defaults are acceptable.

> [!NOTE]
> `BOM_CMD` is required for KiCad < 8.0 as it does not include a BOM generation tool. KiCad 8.0+ includes a BOM generation tool, but it is not as feature rich as KiBOM.

* `BOM_CMD`: [KiBOM](https://github.com/SchrodingersGat/KiBoM): requires install either with `pip` or path to repository - see [Makefile.example](https://github.com/tuna-f1sh/kicad-makefile/blob/main/Makefile.example) and './bin/kibom'. Can be defined with `BOM_CMD` and `BOM_CMD_FLAGS`. Note that by default, the KiBOM script appends to target output so will be re-built whenever `BOM_FILE` is a prerequisite. One can fix this by supplying a 'bom.ini' with `output_file_name = %O`.

## Useful Variables

Defaults shown, can be set in Makefile or environment. Refer to [Makefile.example](https://github.com/tuna-f1sh/kicad-makefile/blob/main/Makefile.example) for others.

```
# Main output folder for generated files
OUTPUT_FOLDER ?= $(PROJECT_ROOT)/output

# Dist sub-folders
DIST_FOLDER ?= $(OUTPUT_FOLDER)/dist
PROD_FOLDER ?= $(OUTPUT_FOLDER)/prod
```
