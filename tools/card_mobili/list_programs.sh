#!/bin/sh

set -e

curl -s -X GET \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/admin/cards/templates?limit=100" \
| python -mjson.tool

echo
