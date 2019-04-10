#!/bin/sh

set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <merchantId> <programId>"
    exit
fi

curl -X GET \
    -q \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/merchants/$1/templates/$2?includeAdditionalInformation=true" \
| python -mjson.tool
