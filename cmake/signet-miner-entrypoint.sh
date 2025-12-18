#!/bin/sh

exec /usr/local/bin/miner \
  --cli="${CLI_CMD}" \
  generate \
  --descriptor "${MINING_XPUB}" \
  --grind-cmd="bitcoin-util grind" \
  --min-nbits \
  --ongoing
