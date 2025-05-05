FROM ubuntu:latest
MAINTAINER John Whittington <git@jbrengineering.co.uk>
LABEL Description="KiCad 9.0 with KiCad Makefile and plugins used"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
      apt upgrade -y && \
      apt install -y wget make zip git python3 python3-pip poppler-utils && \
      apt autoclean -y && \
      apt autoremove -y && \
      apt clean

RUN apt install software-properties-common -y

# Adding the repository for KiCad 9.0 stable release
RUN add-apt-repository --yes ppa:kicad/kicad-9.0-releases && \
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 245D5502FAD7A805

# Install KiCad 9.0
RUN apt update && apt install --install-recommends kicad -y

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
ENV PYTHONPATH=${PYTHONPATH}:/.kicad/scripting/plugins:/usr/share/kicad/scripting/plugins

# Copy default fp-lib-table to user home kicad config
RUN mkdir -p ~/.config/kicad/9.0 && \
      cp /usr/share/kicad/template/fp-lib-table ~/.config/kicad/9.0/fp-lib-table && \
      cp /usr/share/kicad/template/sym-lib-table ~/.config/kicad/9.0/sym-lib-table

# Set env to show running in container
ENV KICADMK_DOCKER=1

# Make the workdir mount
RUN mkdir project/

# Ensure git is happy running in mount
RUN git config --global --add safe.directory /project

WORKDIR project/
