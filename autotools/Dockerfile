FROM alpine:3.23 AS verifier

ARG KNOTS_VERSION

WORKDIR /tmp

RUN KNOTS_MAJOR_VERSION=$(echo ${KNOTS_VERSION} | cut -c1-2) \
 && wget https://bitcoinknots.org/files/${KNOTS_MAJOR_VERSION}.x/${KNOTS_VERSION}/SHA256SUMS \
 && wget https://bitcoinknots.org/files/${KNOTS_MAJOR_VERSION}.x/${KNOTS_VERSION}/SHA256SUMS.asc \
 && wget https://bitcoinknots.org/files/${KNOTS_MAJOR_VERSION}.x/${KNOTS_VERSION}/bitcoin-${KNOTS_VERSION}.tar.gz

RUN apk add --no-cache \
    coreutils \
    curl \
    gnupg \
    jq \
 && curl -s https://api.github.com/repos/bitcoinknots/guix.sigs/contents/builder-keys | jq -r '.[].download_url' | while read url; do curl -s "$url" | gpg --import; done \
 && curl -s https://raw.githubusercontent.com/bitcoinknots/guix.sigs/dee022a799a57b0fd446b62d0c29c25ed412b86b/builder-keys/leo-haf.gpg | gpg --import \
 && gpg --verify SHA256SUMS.asc SHA256SUMS \
 && sha256sum --ignore-missing -c SHA256SUMS


FROM alpine:3.23 AS builder

ARG KNOTS_VERSION

WORKDIR /tmp

COPY --from=verifier /tmp/bitcoin-${KNOTS_VERSION}.tar.gz .

RUN apk add --no-cache \
    autoconf \
    automake \
    bash \
    build-base \
    cmake \
    curl \
    git \
    libtool \
    linux-headers \
    pkgconf \
    upx

RUN tar zxf bitcoin-${KNOTS_VERSION}.tar.gz

RUN ./bitcoin-${KNOTS_VERSION}/autogen.sh

RUN make -C bitcoin-${KNOTS_VERSION}/depends -j$(nproc) NO_QT=1 NO_NATPMP=1 NO_UPNP=1 NO_USDT=1

ENV CFLAGS="-g0 -Os --static -static -fPIC"
ENV CXXFLAGS="-g0 -Os --static -static -fPIC"
ENV LDFLAGS="-Wl,--strip-all -static-libgcc -static-libstdc++"

RUN CONFIG_SITE=$(find /tmp/bitcoin-${KNOTS_VERSION}/depends | grep -E "config\.site$") \
 && mkdir build \
 && cd build \
 && ../bitcoin-${KNOTS_VERSION}/configure \
    CONFIG_SITE=${CONFIG_SITE} \
    --disable-bench \
    --disable-fuzz-binary \
    --disable-gui-tests \
    --disable-maintainer-mode \
    --disable-man \
    --disable-tests \
    --enable-lto \
    --with-daemon=yes \
    --with-gui=no \
    --with-libmultiprocess=no \
    --with-libs=no \
    --with-miniupnpc=no \
    --with-mpgen=no \
    --with-natpmp=no \
    --with-qrencode=no \
    --with-utils=yes

RUN make -C ./build -j$(nproc)

RUN make -C ./build install

RUN upx --lzma /usr/local/bin/*

FROM alpine:3.23 AS final

COPY --from=builder /usr/local/bin/* /usr/local/bin/

RUN apk add --no-cache \
    libgcc \
    libstdc++ \
    tor \
 && adduser -D bitcoin \
 && mkdir /home/bitcoin/.bitcoin \
 && chown bitcoin:bitcoin /home/bitcoin/.bitcoin

USER bitcoin

VOLUME ["/home/bitcoin/.bitcoin"]

# REST interface
EXPOSE 8080

# P2P network (mainnet, testnet, regtest & signet respectively)
EXPOSE 8333 18333 18444 38333

# RPC interface (mainnet, testnet, regtest & signet respectively)
EXPOSE 8332 18332 18443 38332

# ZMQ ports (for block hashes, raw blocks & raw transactions respectively)
EXPOSE 8443 28332 28333

ENTRYPOINT ["/usr/local/bin/bitcoind", "-nodebuglogfile", "-zmqpubhashblock=tcp://0.0.0.0:8443", "-zmqpubrawblock=tcp://0.0.0.0:28332", "-zmqpubrawtx=tcp://0.0.0.0:28333"]
