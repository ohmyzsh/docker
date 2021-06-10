# build with `build --build-arg ZSH_VERSION=<version>` to specify a different zsh version
ARG ZSH_VERSION=latest
FROM zshusers/zsh:${ZSH_VERSION}

LABEL org.label-schema.name="ohmyzsh/zsh"
LABEL org.label-schema.description="Zsh versioned image with Oh My Zsh installed"
LABEL org.label-schema.url="https://github.com/ohmyzsh/docker"
LABEL org.label-schema.vendor="Oh My Zsh"
LABEL maintainer="hello@mcornella.com"

# set UTF-8 locale
ENV LANG=C.UTF-8

# install basic tools
RUN install_packages \
      ca-certificates \
      git \
      curl

# install ohmyzsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
