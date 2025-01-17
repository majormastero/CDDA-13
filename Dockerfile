FROM tgstation/byond:513.1526 as base

FROM base as build_base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git \
    ca-certificates

FROM build_base as rust_g

WORKDIR /rust_g

RUN apt-get install -y --no-install-recommends \
    libssl-dev \
    pkg-config \
    curl \
    gcc-multilib \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --default-host i686-unknown-linux-gnu \
    && git init \
    && git remote add origin https://github.com/tgstation/rust-g

COPY dependencies.sh .

RUN /bin/bash -c "source dependencies.sh \
    && git fetch --depth 1 origin \$RUST_G_VERSION" \
    && git checkout FETCH_HEAD \
    && ~/.cargo/bin/cargo build --release


COPY dependencies.sh .

ENV CC=gcc-7 CXX=g++-7

RUN ln -s /usr/include/mariadb /usr/include/mysql \
    && ln -s /usr/lib/i386-linux-gnu /root/MariaDB \
    && cmake .. \
    && make

FROM base as dm_base

WORKDIR /tgstation

FROM dm_base as build

COPY . .

RUN DreamMaker -max_errors 0 cdda13.dme && tools/deploy.sh /deploy

FROM dm_base

EXPOSE 1337

RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
    libmariadb2 \
    mariadb-client \
    libssl1.0.0 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/.byond/bin

VOLUME [ "/tgmc/config", "/tgmc/data" ]

ENTRYPOINT [ "DreamDaemon", "cdda13.dmb", "-port", "1337", "-trusted", "-close", "-verbose" ]
