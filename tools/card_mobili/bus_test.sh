#!/bin/sh
set -e

ESBTOKEN=0b3ca4d2e7e4886ccf49b769b6355d36817adb32088f1069be09257b02324a7a61ab3eeae8a5981c263623ef30cde39f43d9dd5a951c5ec488032a8126776721e976a592ff575255d4ccdbcadababaee0470a25d03f740d743e7fa2bd4502be617159e87711c1368f3de4a9f8119367258fbb6fcb43b124d1cbc7c79d77843f4d9818a94092893335cc0ea05c41205b3eece456ace4ca1b890f5306c2a9d5ced0f81b180f6d5882734c9ae8a7c31fe38be046a826d22b4bf252c95f7b9123c49d2aa0de5c29fef9dae119b24596f7e41c505e290ce320ee00a7adf088add46498274e5932b78fdbc103b7488a01d3ad83ae0996823151c6f4fc484638c277e31

APIKEY=e5b111753c3f56c0a55d10a2d0e3c27755e4661a

#if [ -z "$1" ]
#then
#    echo "Usage: $0 <userId>"
#    exit
#fi

curl -s -k -X GET \
    --header "Content-Type: application/json" \
    --header "Authorization: WalletPT $APIKEY" \
    "https://services.dev.wallet.pt/certapps/v2/loyalty/subscribers/cards/templates?ESBToken=$ESBTOKEN" \
| python -mjson.tool
