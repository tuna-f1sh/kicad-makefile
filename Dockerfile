FROM ubuntu:latest
MAINTAINER John Whittington <git@jbrengineering.co.uk>
LABEL Description="KiCad 7.0 with KiCad Makefile and plugins used"

RUN apt update && \
      apt upgrade -y && \
      apt install -y wget make zip git python3 python3-pip && \
      apt autoclean -y && \
      apt autoremove -y && \
      apt clean

RUN DEBIAN_FRONTEND=noninteractive apt install software-properties-common -y

# Adding the repository for KiCad 7.0 stable release
RUN add-apt-repository --yes ppa:kicad/kicad-7.0-releases && \
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 245D5502FAD7A805

# Install KiCad 7.0
RUN apt update && apt install kicad -y

# Ensure git is happy running in mount
RUN git config --global --add safe.directory /builds

# Copy kicad-makefile and export environment location
COPY . kicad-makefile/
ENV KICADMK_DIR=/kicad-makefile

# Add KiCad plugins used
RUN pip install kibom && cp /kicad-makefile/bin/kibom /usr/bin
ENV BOM_CMD='python3 -m kibom'

# Add pcbnew module to PYTHONPATH
ENV PYTHONPATH=${PYTHONPATH}:/.kicad/scripting/plugins:/usr/share/kicad/scripting/plugins

# Set env to show running in container
ENV KICADMK_DOCKER=1

# Make the workdir mount
RUN mkdir project/

WORKDIR project/
