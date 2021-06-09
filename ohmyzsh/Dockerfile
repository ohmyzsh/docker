FROM zshusers/zsh:latest

# set UTF-8 locale
ENV LANG=C.UTF-8

# install basic tools
RUN install_packages \
    ca-certificates \
    git \
    curl

# build with `docker build --build-arg OMZ_VERSION=<version>`
# to specify a different ohmyzsh version
ARG OMZ_VERSION=master

# install ohmyzsh
RUN BRANCH=${OMZ_VERSION} \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/${OMZ_VERSION}/tools/install.sh)" "" \
    --unattended
