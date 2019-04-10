#!/bin/sh

set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <merchantId> <cardId>"
    exit
fi

curl -s -X POST \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    -d '{"transactionValue": 10.50}' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/admin/merchants/$1/punchcards/card/$2/redeem"

