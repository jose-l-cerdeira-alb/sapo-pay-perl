#!/bin/sh

set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <userId> <cardId>"
    exit
fi

curl -X DELETE \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/subscribers/$1/cards/$2"

echo
