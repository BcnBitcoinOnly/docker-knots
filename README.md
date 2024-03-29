# Docker Knots

Docker images of [Bitcoin Knots](https://bitcoinknots.org/) for the `linux/amd64`, `linux/arm64` and `linux/arm/v7` architectures.

The images are based on [Alpine Linux](https://alpinelinux.org/) and run bitcoind without a configuration file.

The datadir is at the default `/home/bitcoin/.bitcoin` location.
This directory is designated as a Docker volume.

These are the images' default `ENTRYPOINT` and `CMD`, respectively.
Adjust the `CMD` as required if you want to run the bitcoind daemon with a different configuration.

```dockerfile
ENTRYPOINT ["/usr/local/bin/bitcoind", "-nodebuglogfile"]

CMD ["-zmqpubrawblock=tcp://0.0.0.0:28332", "-zmqpubrawtx=tcp://0.0.0.0:28333"]
```

Customization example based on Docker Compose v2:

```yaml
name: knots-signet

services:
  knots:
    image: 1maa/bitcoin:v26.1.knots20240325
    command: -signet -txindex=1 -zmqpubrawblock=tcp://0.0.0.0:28332 -zmqpubrawtx=tcp://0.0.0.0:28333
```


## Available Versions

* 1maa/bitcoin:v26.1.knots20240325
* 1maa/bitcoin:v25.1.knots20231115


## Deterministic Build Guide

The binaries contained in these images are built from source automatically with GitHub actions, but they are not deterministic.

For a step-by-step guide to do a deterministic build of Bitcoin Knots and attest the resulting binaries with your PGP key, check *TBD*.
