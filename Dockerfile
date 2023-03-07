FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive apt install software-properties-common -y

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

# Add KiCad plugins used
# RUN git clone https://github.com/SchrodingersGat/kibom && \
#   echo 'alias kibom="python3 /kibom/KiBOM_CLI.py"' >> ~/.bashrc
RUN pip install kibom
COPY ./bin/kibom /usr/bin

# Copy kicad-makefile and export environment location
COPY . kicad-makefile/
RUN echo 'export KICADMK_DIR=/kicad-makefile' >> ~/.bashrc

# Add pcbnew module to PYTHONPATH
ENV PYTHONPATH=${PYTHONPATH}:/.kicad/scripting/plugins:/usr/share/kicad/scripting/plugins

# Make the workdir mount
RUN mkdir project/

WORKDIR project/
