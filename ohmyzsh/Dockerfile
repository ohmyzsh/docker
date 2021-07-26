FROM zshusers/zsh:latest

LABEL org.label-schema.name="ohmyzsh"
LABEL org.label-schema.description="Oh My Zsh versioned image"
LABEL org.label-schema.url="https://github.com/ohmyzsh/docker"
LABEL org.label-schema.vendor="Oh My Zsh"
LABEL maintainer="Marc Cornellà <hello@mcornella.com>"

# set UTF-8 locale
ENV LANG=C.UTF-8

# install basic tools
RUN install_packages \
    ca-certificates \
    git \
    curl

# build with `build --build-arg OMZ_VERSION=<version>` to specify a different ohmyzsh version
ARG OMZ_VERSION=master

# install ohmyzsh
RUN BRANCH=${OMZ_VERSION} \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/${OMZ_VERSION}/tools/install.sh)" "" \
    --unattended
