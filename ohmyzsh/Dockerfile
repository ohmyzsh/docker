ARG ZSH_BASE_IMAGE=ohmyzsh/zsh:latest
FROM ${ZSH_BASE_IMAGE}

# image metadata
LABEL org.opencontainers.image.title="ohmyzsh"
LABEL org.opencontainers.image.description="Oh My Zsh versioned image"
LABEL org.opencontainers.image.url="https://github.com/ohmyzsh/docker"
LABEL org.opencontainers.image.source="https://github.com/ohmyzsh/docker"
LABEL org.opencontainers.image.documentation="https://github.com/ohmyzsh/docker/tree/master/ohmyzsh"
LABEL org.opencontainers.image.vendor="Oh My Zsh"
LABEL org.opencontainers.image.authors="Marc Cornellà <hello@mcornella.com>, Carlo Sala <carlosalag@protonmail.com>"

# set UTF-8 locale
ENV LANG=C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/sh", "-euc"]

# install basic tools
RUN apt-get update; \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl; \
    apt-get clean; \
    rm -rf \
      /var/lib/apt/lists/* \
      /usr/share/doc/*

# specify the Oh My Zsh version string
ARG OMZ_VERSION=master

# install ohmyzsh
RUN BRANCH=${OMZ_VERSION} \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/${OMZ_VERSION}/tools/install.sh)" "" \
    --unattended
