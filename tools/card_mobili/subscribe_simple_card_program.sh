#!/bin/bash


set -e

#this is specific for program 897 as the fields must match

subscribers=(246 291 292 332 470 478)
program=897

for i in ${subscribers[*]}; do
    ts=`date +%s%N`
    echo "subscribing ${i} to ${program} with CN $ts"
    curl -X POST \
        --basic \
        --header "Content-Type: application/json" \
        -u 'pt.b2b@cardmobili.com':'telecom!123' \
        -d '{"fields":[{"id":494954,"content":null},{"id":494956,"content":null},{"id":494958,"content":null}],"cardNumber":"t '$ts'","barcodeNumber":""}' \
        "http://vmdev-cardmobili02.vmdev.bk.sapo.pt/api/rest/b2b/v1/subscribers/${i}/cards/templates/${program}" \
    | python -mjson.tool
done
