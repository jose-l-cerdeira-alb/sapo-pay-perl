#!/bin/bash

PACKAGE=$1
FILENAME=`basename $1`
STAGING=vm-pay02.vmdev.bk.sapo.pt
DEVELOPMENT=vm-pay01.vmdev.bk.sapo.pt
REMOTE_DIR=/tmp

function deploy 
{
	HOST=$1
	echo "deploying to $HOST..."
	
	if ! scp $PACKAGE $HOST:$REMOTE_DIR
	then
		echo "Something went wrong. Aborting."
		exit 1
	fi
	
	if ! ssh  $HOST "sudo dpkg -i $REMOTE_DIR/$FILENAME && rm -v $REMOTE_DIR/$FILENAME"
	then
		echo "Something went wrong. Aborting."
		exit 1
	fi
}

if [ -z "$PACKAGE" ]
then
	echo "You need to supply package name to deploy."
	exit 1
fi

if [ ! -f "$PACKAGE" ]
then
	echo "The package file '$PACKAGE' doesn't exist."
	exit 1
fi

if [ "$2" == "staging" ]
then
	echo "Deploying $PACKAGE to ***Staging*** in 5s"
	sleep 5
	deploy $STAGING
else
	echo "Deploying $PACKAGE to ***Development***"
	deploy $DEVELOPMENT
fi

echo "Deploy completed ok."

