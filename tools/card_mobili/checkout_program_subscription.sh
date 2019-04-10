curl \
    -X POST \
    -d '{"operation_id":"05b58399-fce5-4312-965a-05bab6149bdb","decision":"ACCEPT"}' \
    http://payws.local/api/v2/loyalty/subscribers/cards/templates/20 \
    -H "Authorization: WalletPT 7a0eb41208209639eda9bf765b6cb04d59fb9e34" \
    -H "Content-Type: application/json" | python -mjson.tool

