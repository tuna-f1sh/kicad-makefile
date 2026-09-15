FROM ubuntu:latest
LABEL maintainer="John Whittington <git@jbrengineering.co.uk>"
LABEL Description="KiCad 10.0 with KiCad Makefile and plugins used"

ARG DEBIAN_FRONTEND=noninteractive

# Set to a non-empty value (eg "--no-install-recommends") to build a 'lite'
# image without the bundled KiCad footprints/symbols/3D models/templates
# (saves several GB). When lite, mount your own libraries/tables via the
# /config mount point (see docker-entrypoint.sh and README).
ARG KICAD_INSTALL_FLAGS=--install-recommends

RUN apt update && \
      apt upgrade -y && \
      apt install -y wget make zip git python3 python3-pip poppler-utils && \
      apt autoclean -y && \
      apt autoremove -y && \
      apt clean

RUN apt install software-properties-common curl -y

# Adding the repository for KiCad 10.0 stable release
RUN add-apt-repository --yes ppa:kicad/kicad-10.0-releases

# Install KiCad 10.0
RUN apt update && apt install ${KICAD_INSTALL_FLAGS} kicad -y

# Copy kicad-makefile and export environment location
COPY . kicad-makefile/
ENV KICADMK_DIR=/kicad-makefile

# Add KiCad plugins used
RUN git clone https://github.com/SchrodingersGat/kibom && \
      cd kibom && \
      pip install --break-system-packages . && \
      cp /kicad-makefile/bin/kibom /usr/bin
ENV BOM_CMD='python3 -m kibom'

# Add pcbnew module to PYTHONPATH
ENV PYTHONPATH=/.kicad/scripting/plugins:/usr/share/kicad/scripting/plugins

# Copy default fp-lib-table/sym-lib-table to user home kicad config, falling
# back to empty tables when built 'lite' (no kicad-templates package)
RUN mkdir -p ~/.config/kicad/10.0 && \
      cp /usr/share/kicad/template/fp-lib-table ~/.config/kicad/10.0/fp-lib-table 2>/dev/null || \
      printf '(fp_lib_table\n  (version 7)\n)\n' > ~/.config/kicad/10.0/fp-lib-table && \
      cp /usr/share/kicad/template/sym-lib-table ~/.config/kicad/10.0/sym-lib-table 2>/dev/null || \
      printf '(sym_lib_table\n  (version 7)\n)\n' > ~/.config/kicad/10.0/sym-lib-table

# Set env to show running in container
ENV KICADMK_DOCKER=1

# Make the workdir mount
RUN mkdir -p /project

# Ensure git is happy running in mount
RUN git config --global --add safe.directory /project

# Make the optional user config/libraries mount point (fp-lib-table,
# sym-lib-table, 3rd party libraries etc); see docker-entrypoint.sh
RUN mkdir -p /config
ENTRYPOINT ["/kicad-makefile/bin/docker-entrypoint.sh"]

WORKDIR /project
CMD ["make"]
