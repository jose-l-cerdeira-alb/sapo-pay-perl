#!/bin/sh
set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <programId>"
    exit
fi

curl -s -X GET \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/admin/templates/$1/cards?includeAdditionalInformation=true" \
| python -mjson.tool
