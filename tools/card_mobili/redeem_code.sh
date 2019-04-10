#!/bin/sh

set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <merchantId> <redeemCode>"
    exit
fi

curl -X POST \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    -d '{}' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/admin/merchants/$1/punchcards/redeem/$2"

echo
