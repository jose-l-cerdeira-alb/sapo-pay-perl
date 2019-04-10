#!/bin/sh
set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <merchantId> <cardId>"
    exit
fi

curl -s -X GET \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/admin/merchants/$1/templates/card/$2?includeAdditionalInformation=truex" \
| python -mjson.tool
