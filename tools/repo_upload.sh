#!/bin/bash
set -e

if [ -z "$1" ]
then
	echo "Usage: $0 <package.deb> [production]"
	exit 1
fi

PACKAGE=$1
FILENAME=`basename $1`
STAGING_REPO=paydebs@paystg-jumpbox01.paystg.bk.sapo.pt:tree/tmp
PROD_REPO=not_available
BRANCH_STRING="Created from branch"

if [ ! -f "$PACKAGE" ]
then
	echo "The package file '$PACKAGE' doesn't exist."
	exit 1
fi

if ( ! dpkg-sig --verify $PACKAGE | grep -q "^GOODSIG" )
then
    echo "Couldn't verify package signature. Aborting."
    exit 1
fi

echo "Package is signed."

if [ "$2" == "production" ]
then
    echo Uploading to *PRODUCTION* repository
    REPO=$PROD_REPO
    BRANCH=master
else
    echo Uploading to staging repository
    REPO=$STAGING_REPO
    BRANCH=staging
fi

# JCC this maked no sense in this repo
#if ( ! dpkg -I $PACKAGE | grep -q "$BRANCH_STRING $BRANCH" )
#then
    #echo "Refusing to upload package from wrong branch to $REPO (should be from branch $BRANCH)"
    #exit 1
#fi
#echo "Package branch $BRANCH is correct."

if ! ( (echo "put $PACKAGE"; echo "rename $FILENAME ../$FILENAME") | sftp -q $REPO )
then
    echo "Something wrong with sftp file uploading."
    exit 1
fi
