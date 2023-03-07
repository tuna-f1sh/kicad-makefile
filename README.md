A Makefile for KiCad 7.0+. It leverages the new `kicad-cli` command included in 7.0 to generate output data for distribution and production.

# Usage

1. Clone this repository somewhere and define an environment variable `KICADMK_DIR` to the folder:
`export KICADMK_DIR=/home/me/kicad-makefile`
2. Copy the example Makefile 'Makefile.example' to the KiCad project to build:
`cp Makefile.example /home/me/my_project`
3. Edit the example Makefile referring to comments as a guide.
4. Run `make` to run default target, which builds outputs and a distribution and production .zip:
* ./output/dist/my_project.zip: sch renders, pcb renders, bom, gerbers, pos and drill files.
* ./output/prod/my_project-prod.zip: bom, gerbers, pos and drill files.

Refer to 'Kicad.mk' for other targets.

The project is alpha status and also consider that the `kicad-cli` command is at an early stage; things might change!
