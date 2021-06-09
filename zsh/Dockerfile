# build with `docker build --build-arg ZSH_VERSION=<version>`
# to specify a different zsh version
ARG ZSH_VERSION=latest
FROM zshusers/zsh:${ZSH_VERSION}

# set UTF-8 locale
ENV LANG=C.UTF-8

# install basic tools
RUN install_packages \
      ca-certificates \
      git \
      curl

# install ohmyzsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
