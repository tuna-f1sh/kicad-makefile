#!/bin/sh
# Entrypoint for kicad-makefile docker image.
#
# Allows a user to mount their own KiCad config (fp-lib-table, sym-lib-table,
# 3rd party plugins etc) into the container without overwriting the whole
# ~/.config/kicad/<version> directory - useful so ERC/DRC checks can resolve
# user symbols/footprints instead of just warning that they are missing.
#
# Mount a directory containing any of the below files (or others found in a
# real ~/.config/kicad/<version> folder) to /config, eg:
#
#   docker run --rm -v "$(pwd)":/project -v "$(pwd)/kicad-config":/config kicad-makefile:latest make
#
# Any file present in /config is copied over the image default, so partial
# overrides (eg just fp-lib-table) are supported.

set -e

KICAD_CONFIG_DIR="${KICAD_CONFIG_DIR:-$HOME/.config/kicad/10.0}"

if [ -d /config ]; then
    mkdir -p "$KICAD_CONFIG_DIR"
    find /config -mindepth 1 -maxdepth 1 -exec cp -rf {} "$KICAD_CONFIG_DIR"/ \;
fi

exec "$@"
