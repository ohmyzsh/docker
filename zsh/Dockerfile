ARG DEBIAN_VERSION=trixie-slim
ARG ZSH_VERSION=5.9.2

FROM debian:${DEBIAN_VERSION} AS builder
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/sh", "-euxc"]

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
      autoconf \
      autotools-dev \
      bsdextrautils \
      bzip2 \
      ca-certificates \
      curl \
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

COPY patches/ /tmp/zsh-patches/

WORKDIR /usr/src

ARG ZSH_VERSION
RUN if [ "$ZSH_VERSION" = "master" ] || dpkg --compare-versions "$ZSH_VERSION" ge 5.9.1; then \
      exit 0; \
    fi; \
    curl -fL \
      -o pcre-8.45.tar.bz2 \
      https://downloads.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.bz2; \
    echo "4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8  pcre-8.45.tar.bz2" | sha256sum -c -; \
    tar -xjf pcre-8.45.tar.bz2; \
    cd pcre-8.45; \
    ./configure \
      --disable-cpp \
      --disable-shared \
      --enable-static \
      --with-pic \
      --enable-utf \
      --enable-unicode-properties \
      --enable-jit; \
    make -j"$(nproc)"; \
    make install

RUN if [ "$ZSH_VERSION" = "master" ]; then \
      ZSH_REF="master"; \
    else \
      ZSH_REF="zsh-$ZSH_VERSION"; \
    fi; \
    git clone --depth 1 --branch "$ZSH_REF" https://github.com/zsh-users/zsh.git zsh

WORKDIR /usr/src/zsh

RUN for patch_file in /tmp/zsh-patches/*.patch; do \
      patch -N -s -p1 -r /dev/null -i "$patch_file" || true; \
    done; \
    ./Util/preconfig; \
    install -m 0755 /usr/share/misc/config.sub Config/config.sub; \
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
    if [ "$ZSH_VERSION" = "master" ] || dpkg --compare-versions "$ZSH_VERSION" ge 5.0.3; then \
      install_targets="$install_targets install.runhelp"; \
    fi; \
    make DESTDIR=/opt/zsh $install_targets; \
    strip /opt/zsh/usr/bin/zsh; \
    find /opt/zsh -type f -name '*.a' -delete

FROM debian:${DEBIAN_VERSION}
ARG DEBIAN_FRONTEND=noninteractive

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
