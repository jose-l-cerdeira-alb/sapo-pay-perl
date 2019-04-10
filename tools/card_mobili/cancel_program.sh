#!/bin/sh

set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <programId>"
    exit
fi

curl -X DELETE \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/admin/loyaltyprograms/$1"

echo
