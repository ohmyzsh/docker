ARG DEBIAN_VERSION=trixie-slim
ARG ZSH_VERSION=5.9.1

FROM debian:${DEBIAN_VERSION} AS builder
ARG ZSH_VERSION
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/sh", "-euxc"]

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
      autoconf \
      bsdextrautils \
      ca-certificates \
      gcc \
      git \
      groff-base \
      libcap-dev \
      libgdbm-dev \
      libncurses-dev \
      libpcre2-dev \
      make \
      patch \
      texinfo \
      yodl

WORKDIR /usr/src

RUN if [ "$ZSH_VERSION" = "master" ]; then \
      ZSH_REF="master"; \
    else \
      ZSH_REF="zsh-$ZSH_VERSION"; \
    fi; \
    git clone --depth 1 --branch "$ZSH_REF" https://github.com/zsh-users/zsh.git zsh

COPY patches/ /tmp/zsh-patches/

WORKDIR /usr/src/zsh

RUN for patch_file in /tmp/zsh-patches/*.patch; do \
      patch -N -s -p1 -r /dev/null -i "$patch_file" || true; \
    done; \
    ./Util/preconfig; \
    export CFLAGS="${CFLAGS-} -Wno-error=implicit-int -Wno-error=implicit-function-declaration"; \
    build_platform="$(dpkg --print-architecture)"; \
    case "$build_platform" in \
      amd64) build_platform="x86_64" ;; \
      arm64) build_platform="aarch64" ;; \
    esac; \
    ./configure \
      --build="${build_platform}-unknown-linux-gnu" \
      --prefix=/usr \
      --mandir=/usr/share/man \
      --infodir=/usr/share/info \
      --with-tcsetpgrp \
      --enable-pcre \
      --enable-cap \
      --enable-gdbm \
      --enable-multibyte \
      --with-term-lib='ncursesw tinfo' \
      --enable-etcdir=/etc/zsh; \
    make -j"$(nproc)"; \
    install_targets="install.bin install.modules install.fns install.man install.info"; \
    if dpkg --compare-versions "$ZSH_VERSION" ge 5.0.3; then \
      install_targets="$install_targets install.runhelp"; \
    fi; \
    make DESTDIR=/opt/zsh $install_targets; \
    strip /opt/zsh/usr/bin/zsh; \
    find /opt/zsh -type f -name '*.a' -delete

FROM debian:${DEBIAN_VERSION}

# image metadata
LABEL org.opencontainers.image.title="ohmyzsh/zsh"
LABEL org.opencontainers.image.description="Zsh versioned image built from zsh-users/zsh"
LABEL org.opencontainers.image.url="https://github.com/ohmyzsh/docker"
LABEL org.opencontainers.image.source="https://github.com/ohmyzsh/docker"
LABEL org.opencontainers.image.documentation="https://github.com/ohmyzsh/docker/tree/master/zsh"
LABEL org.opencontainers.image.vendor="Oh My Zsh"
LABEL org.opencontainers.image.authors="Marc Cornellà <hello@mcornella.com>, Carlo Sala <carlosalag@protonmail.com>"

# set UTF-8 locale
ENV LANG=C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/sh", "-euxc"]

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
      info \
      less \
      libcap2 \
      libgdbm6t64 \
      libncursesw6 \
      libpcre2-8-0 \
      man-db; \
    apt-get clean; \
    rm -rf \
      /var/lib/apt/lists/* \
      /usr/share/doc/*

COPY --from=builder /opt/zsh/ /

RUN if ! grep -qx /usr/bin/zsh /etc/shells; then \
      echo /usr/bin/zsh >> /etc/shells; \
    fi; \
    chsh -s /usr/bin/zsh root

CMD ["zsh"]
