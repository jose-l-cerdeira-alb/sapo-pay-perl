#!/bin/sh

set -e

if [ -z "$1" ]
then
    echo "Usage: $0 <merchantId>"
    exit
fi

curl -s -X POST \
    --basic \
    --header "Content-Type: application/json" \
    -u 'pt.b2b@cardmobili.com':'telecom!123' \
    -d '{"title": "Test Program 2", "totalNumberPunchesEvents": 10, "requiredValueToPunch": 5.50, "expirationDate": "2015-12-20T10:00:00Z", "rewardDescription": "Test Reward Description", "termsAndConditions": "Test Terms and Conditions", "daysToRedeem": 7, "cardImageMostCommonHexColor": "AD4EF5"}' \
    "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/admin/punchcards/merchants/$1" | python -mjson.tool

