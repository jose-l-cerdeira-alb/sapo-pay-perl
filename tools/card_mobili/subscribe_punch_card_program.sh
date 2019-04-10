#!/bin/sh

set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <userId> <punchCardProgramId>"
    exit
fi

curl -X POST \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    -d '{"isAnonymous": true}' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/subscribers/$1/punchcards/templates/$2" 
#\| python -mjson.tool
