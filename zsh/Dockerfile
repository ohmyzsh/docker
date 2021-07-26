# This Dockerfile image is optimized to maximize Docker layer cache usage among
# the builds of the different image tags. Since the different tags of the image
# are built at the same time, we can cache the dependency-installation step
# and then copy the zsh image (the thing that changes between tags) on top of it.
#
# Idea taken from: https://stackoverflow.com/a/48545669/5798232.
#
# Step 1: reference the parent image in a pre-build step.
# Step 2: copy the parent image filesystem on top of our new image, *after*
# dependencies have been installed.

## PRE-BUILD STEP
ARG ZSH_VERSION=latest
FROM zshusers/zsh:${ZSH_VERSION} as zsh


## MAIN IMAGE BUILD

# IMPORTANT: this is the image that zshusers/zsh is based on. We need to use
# the same for compatibility so that there are no conflicts in the COPY step.
FROM bitnami/minideb:buster

# image metadata
LABEL org.opencontainers.image.title="ohmyzsh/zsh"
LABEL org.opencontainers.image.description="Zsh versioned image with Oh My Zsh installed"
LABEL org.opencontainers.image.url="https://github.com/ohmyzsh/docker"
LABEL org.opencontainers.image.vendor="Oh My Zsh"
LABEL org.opencontainers.image.authors="Marc Cornellà <hello@mcornella.com>"
LABEL maintainer="Marc Cornellà <hello@mcornella.com>"

# set UTF-8 locale
ENV LANG=C.UTF-8

# install basic tools
RUN install_packages \
      ca-certificates \
      git \
      curl

# this is the point where we copy Zsh from the parent image
COPY --from=zsh / /

# install ohmyzsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
