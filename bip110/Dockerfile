FROM alpine:3.23 AS verifier

WORKDIR /tmp

RUN wget https://github.com/dathonohm/bitcoin/releases/download/v29.2.knots20251110%2Bbip110-v0.1/SHA256SUMS \
 && wget https://github.com/dathonohm/bitcoin/releases/download/v29.2.knots20251110%2Bbip110-v0.1/SHA256SUMS.asc \
 && wget https://github.com/dathonohm/bitcoin/releases/download/v29.2.knots20251110%2Bbip110-v0.1/bitcoin-29.2.knots20251110+bip110-v0.1.tar.gz

RUN apk add --no-cache \
    coreutils \
    curl \
    gnupg \
    jq \
 && curl -s https://api.github.com/repos/dathonohm/guix.sigs/contents/builder-keys | jq -r '.[].download_url' | while read url; do curl -s "$url" | gpg --import; done \
 && gpg --verify SHA256SUMS.asc SHA256SUMS \
 && sha256sum --ignore-missing -c SHA256SUMS \
 && mv bitcoin-29.2.knots20251110+bip110-v0.1.tar.gz bitcoin.tar.gz


FROM alpine:3.23 AS builder

WORKDIR /tmp

COPY --from=verifier /tmp/bitcoin.tar.gz .

RUN apk add --no-cache \
    bash \
    build-base \
    cmake \
    curl \
    linux-headers \
    pkgconf \
    upx

RUN tar zxf bitcoin.tar.gz

RUN make -C bitcoin-29.2.knots20251110+bip110-v0.1/depends -j$(nproc) NO_QT=1 NO_NATPMP=1 NO_UPNP=1 NO_USDT=1

RUN cmake -S bitcoin-29.2.knots20251110+bip110-v0.1 -B build \
    -DAPPEND_CPPFLAGS=-g0 \
    -DAPPEND_LDFLAGS=-Wl,--strip-all \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_TX=ON \
    -DBUILD_UTIL=ON \
    -DBUILD_WALLET_TOOL=ON \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DINSTALL_MAN=OFF \
    -DREDUCE_EXPORTS=ON \
    -DSECP256K1_APPEND_CFLAGS=-g0 \
    -DSECP256K1_APPEND_LDFLAGS=-Wl,--strip-all \
    -DWITH_BDB=ON \
    -DWITH_ZMQ=ON \
    --toolchain $(find /tmp/bitcoin-29.2.knots20251110+bip110-v0.1/depends | grep -E "toolchain\.cmake$")

RUN cmake --build build -j $(nproc)

RUN cmake --install build

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
