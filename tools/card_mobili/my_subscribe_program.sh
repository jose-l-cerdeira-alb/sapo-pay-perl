#!/bin/sh

set -e

APIKEY=e5b111753c3f56c0a55d10a2d0e3c27755e4661a

if [ -z "$1" ]
then
    echo "Usage: $0 <programId>"
    exit
fi

curl -s -k -X POST \
    --basic \
    --header "Content-Type: application/json" \
    --header "Authorization: WalletPT $APIKEY" \
    -d '{"decision": "ACCEPT"}' \
    "http://payws.local/loyalty/subscribers/cards/templates/$1" | python -mjson.tool
