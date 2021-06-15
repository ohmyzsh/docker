FROM bitnami/minideb:buster AS builder
ARG ref=master
WORKDIR /tmp/zsh-build
RUN install_packages curl \
                     ca-certificates \
                     autoconf \
                     make \
                     libtool \
                     libcap-dev \
                     libtinfo5 \
                     libncursesw5-dev \
                     libpcre3-dev \
                     libgdbm-dev \
                     yodl \
                     groff \
                     man-db \
                     texinfo \
                     groff
RUN curl -L https://api.github.com/repos/zsh-users/zsh/tarball/$ref | tar xz --strip=1

# Patch signames.c generation
COPY 0001-signals.patch .
RUN install_packages patch
RUN patch -s -p1 -r /dev/null < 0001-signals.patch || true

RUN ./Util/preconfig
RUN ./configure --prefix /usr \
                --enable-pcre \
                --enable-cap \
                --enable-multibyte \
                --with-term-lib='ncursesw tinfo' \
                --with-tcsetpgrp
RUN make
RUN make -C Etc all FAQ FAQ.html
RUN if test $ref = "master" ; then install_packages cm-super-minimal texlive-fonts-recommended texlive-latex-base texlive-latex-recommended ghostscript bsdmainutils ; fi
RUN if test $ref = "master" ; then make -C Doc everything ; fi
RUN make install DESTDIR=/tmp/zsh-install
RUN make install.info DESTDIR=/tmp/zsh-install || true

FROM bitnami/minideb:buster
LABEL maintainer="https://github.com/zsh-users/zsh-docker"
WORKDIR /
COPY --from=builder /tmp/zsh-install /
RUN add-shell /usr/bin/zsh
RUN install_packages libcap2 \
                     libtinfo5 \
                     libncursesw5 \
                     libpcre3 \
                     libgdbm6
CMD ["/usr/bin/zsh","-l"]

# Oh My Zsh specific instructions
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
