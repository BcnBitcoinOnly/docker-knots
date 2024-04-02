FROM alpine:3.19 AS verifier

ARG KNOTS_VERSION

WORKDIR /tmp

RUN KNOTS_MAJOR_VERSION=$(echo ${KNOTS_VERSION} | cut -c1-2) \
 && wget https://bitcoinknots.org/files/${KNOTS_MAJOR_VERSION}.x/${KNOTS_VERSION}/SHA256SUMS \
 && wget https://bitcoinknots.org/files/${KNOTS_MAJOR_VERSION}.x/${KNOTS_VERSION}/SHA256SUMS.asc \
 && wget https://bitcoinknots.org/files/${KNOTS_MAJOR_VERSION}.x/${KNOTS_VERSION}/bitcoin-${KNOTS_VERSION}.tar.gz

COPY builder_pubkeys.pem .

RUN apk add --no-cache \
    coreutils \
    gnupg \
    gnupg-keyboxd \
 && gpg --import builder_pubkeys.pem \
 && gpg --verify SHA256SUMS.asc SHA256SUMS \
 && sha256sum --ignore-missing -c SHA256SUMS


FROM alpine:3.18 AS builder

ARG KNOTS_VERSION

WORKDIR /tmp

COPY --from=verifier /tmp/bitcoin-${KNOTS_VERSION}.tar.gz .

RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    curl \
    git \
    libtool \
    linux-headers \
    pkgconf

RUN tar zxf bitcoin-${KNOTS_VERSION}.tar.gz

RUN ./bitcoin-${KNOTS_VERSION}/autogen.sh

RUN make -C bitcoin-${KNOTS_VERSION}/depends -j$(nproc) NO_QT=1 NO_NATPMP=1 NO_UPNP=1 NO_USDT=1

ENV CFLAGS="-O2 --static -static -fPIC"
ENV CXXFLAGS="-O2 --static -static -fPIC"
ENV LDFLAGS="-s -static-libgcc -static-libstdc++"

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


FROM alpine:3.19 AS final

COPY --from=builder /usr/local/bin/* /usr/local/bin/

RUN apk add --no-cache \
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

# ZMQ ports (for blocks & transactions respectively)
EXPOSE 28332 28333

ENTRYPOINT ["/usr/local/bin/bitcoind", "-nodebuglogfile", "-zmqpubrawblock=tcp://0.0.0.0:28332", "-zmqpubrawtx=tcp://0.0.0.0:28333"]
