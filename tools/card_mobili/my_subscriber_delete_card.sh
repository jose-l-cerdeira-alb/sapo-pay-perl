#!/bin/sh

set -e

APIKEY=e5b111753c3f56c0a55d10a2d0e3c27755e4661a

if [ -z "$1" ]
then
    echo "Usage: $0 <cardId>"
    exit
fi

curl -s -k -X DELETE \
    --basic \
    --header "Content-Type: application/json" \
    --header "Authorization: WalletPT $APIKEY" \
    "http://payws.local/loyalty/subscribers/cards/$1" | python -mjson.tool
