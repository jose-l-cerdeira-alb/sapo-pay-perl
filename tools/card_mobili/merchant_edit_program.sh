#!/bin/sh

set -e

if [ -z "$2" ]
then
    echo "Usage: $0 <merchantId> <programId>"
    exit
fi

curl -s -X POST \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    -d '{"expirationDate": "2015-12-20T10:00:00Z"}' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/admin/merchants/$1/templates/$2"

