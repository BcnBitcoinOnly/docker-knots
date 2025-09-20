FROM alpine:3.22 AS verifier

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
    gnupg-keyboxd \
    jq \
 && curl -s https://api.github.com/repos/bitcoinknots/guix.sigs/contents/builder-keys | jq -r '.[].download_url' | while read url; do curl -s "$url" | gpg --import; done \
 && gpg --verify SHA256SUMS.asc SHA256SUMS \
 && sha256sum --ignore-missing -c SHA256SUMS


FROM alpine:3.22 AS builder

ARG KNOTS_VERSION

WORKDIR /tmp

COPY --from=verifier /tmp/bitcoin-${KNOTS_VERSION}.tar.gz .

RUN apk add --no-cache \
    bash \
    build-base \
    cmake \
    curl \
    linux-headers \
    pkgconf

RUN tar zxf bitcoin-${KNOTS_VERSION}.tar.gz

RUN make -C bitcoin-${KNOTS_VERSION}/depends -j$(nproc) NO_QT=1 NO_NATPMP=1 NO_UPNP=1 NO_USDT=1

RUN cmake -S bitcoin-${KNOTS_VERSION} -B build \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_TX=ON \
    -DBUILD_UTIL=ON \
    -DBUILD_WALLET_TOOL=ON \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DINSTALL_MAN=OFF \
    -DREDUCE_EXPORTS=ON \
    -DWITH_BDB=ON \
    -DWITH_ZMQ=ON \
    --toolchain $(find /tmp/bitcoin-${KNOTS_VERSION}/depends | grep -E "toolchain\.cmake$")

RUN cmake --build build -j $(nproc)

RUN cmake --install build


FROM alpine:3.22 AS final

ARG KNOTS_VERSION

COPY --from=builder /usr/local/bin/* /usr/local/bin/
COPY --from=builder /tmp/bitcoin-${KNOTS_VERSION}/test/functional/test_framework /opt/bitcoin/test/functional/test_framework
COPY --from=builder /tmp/bitcoin-${KNOTS_VERSION}/contrib/signet/miner           /opt/bitcoin/contrib/signet/miner

RUN apk add --no-cache \
    python3 \
    tor \
 && adduser -D bitcoin \
 && mkdir /home/bitcoin/.bitcoin \
 && chown bitcoin:bitcoin /home/bitcoin/.bitcoin \
 && ln -s /opt/bitcoin/contrib/signet/miner /usr/local/bin/miner

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
