ARG ZSH_VERSION=latest
FROM zshusers/zsh:${ZSH_VERSION}

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

# install ohmyzsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
