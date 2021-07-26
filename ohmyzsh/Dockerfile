# This image will always use the latest stable version of zsh
FROM zshusers/zsh:latest

# image metadata
LABEL org.opencontainers.image.title="ohmyzsh"
LABEL org.opencontainers.image.description="Oh My Zsh versioned image"
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

# specify the Oh My Zsh version string
ARG OMZ_VERSION=master

# install ohmyzsh
RUN BRANCH=${OMZ_VERSION} \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/${OMZ_VERSION}/tools/install.sh)" "" \
    --unattended
