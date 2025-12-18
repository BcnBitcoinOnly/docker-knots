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
 && gpg --verify SHA256SUMS.asc SHA256SUMS \
 && sha256sum --ignore-missing -c SHA256SUMS

RUN tar zxf bitcoin-${KNOTS_VERSION}.tar.gz \
 && mv bitcoin-${KNOTS_VERSION} bitcoin


FROM alpine:3.23 AS final

ENV CLI_CMD=bitcoin-cli
ENV MINING_XPUB=tr(tpubXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/0/*)#xxxxxxxx

COPY --from=1maa/bitcoin:latest /usr/local/bin/bitcoin-cli  /usr/local/bin/bitcoin-cli
COPY --from=1maa/bitcoin:latest /usr/local/bin/bitcoin-util /usr/local/bin/bitcoin-util

COPY --from=verifier /tmp/bitcoin/test/functional/test_framework /usr/local/src/bitcoin/test/functional/test_framework
COPY --from=verifier /tmp/bitcoin/contrib/signet/miner           /usr/local/src/bitcoin/contrib/signet/miner

COPY --chown=0:0 --chmod=755 entrypoint.sh /opt/entrypoint.sh

RUN apk add --no-cache \
    python3 \
 && adduser -D bitcoin \
 && ln -s /usr/local/src/bitcoin/contrib/signet/miner /usr/local/bin/miner

USER bitcoin

STOPSIGNAL SIGINT

ENTRYPOINT ["/opt/entrypoint.sh"]
