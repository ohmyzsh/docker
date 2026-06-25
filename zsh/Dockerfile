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
      yodl; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

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
      --enable-pcre \
      --enable-cap \
      --enable-gdbm \
      --enable-multibyte \
      --with-term-lib='ncursesw tinfo' \
      --enable-etcdir=/etc/zsh; \
    make -j"$(nproc)"; \
    make DESTDIR=/opt/zsh install.bin install.modules install.fns install.man install.info install.runhelp; \
    strip /opt/zsh/usr/bin/zsh; \
    find /opt/zsh -type f -name '*.a' -delete

FROM debian:${DEBIAN_VERSION}

# image metadata
LABEL org.opencontainers.image.title="ohmyzsh/zsh"
LABEL org.opencontainers.image.description="Zsh versioned image built from zsh-users/zsh"
LABEL org.opencontainers.image.url="https://github.com/ohmyzsh/docker"
LABEL org.opencontainers.image.vendor="Oh My Zsh"
LABEL org.opencontainers.image.authors="Marc Cornellà <hello@mcornella.com>"
LABEL maintainer="Marc Cornellà <hello@mcornella.com>"

# set UTF-8 locale
ENV LANG=C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/sh", "-euxc"]

RUN apt-get update; \
    apt-get install -y --no-install-recommends \
      info \
      less \
      libgdbm6 \
      libncursesw6 \
      man-db; \
    apt-get clean; \
    rm -rf \
      /var/lib/apt/lists/* \
      /var/cache/apt/* \
      /var/cache/man/* \
      /usr/share/doc/* \
      /tmp/* \
      /var/tmp/*

COPY --from=builder /opt/zsh/ /

RUN if ! grep -qx /usr/bin/zsh /etc/shells; then \
      echo /usr/bin/zsh >> /etc/shells; \
    fi

CMD ["zsh"]
