#!/bin/sh
set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <userId>"
    exit
fi

curl -s -X GET \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/subscribers/$1/cards/templates?country=PT&includeOwnedByUser=true" \
| python -mjson.tool
