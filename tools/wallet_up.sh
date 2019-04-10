#!/bin/sh



USR=$1
if [ "$1" = "" ]
then
 USR=$USER
fi

DIR=/home/$USR/wallet
SERVER=vm-pay01
WALLETLINK=/servers/pti-wallet-wrapper/wrapper
CONFLINK=/etc/lighttpd/lighttpd.conf
CONFFILE=$WALLETLINK/lighttpd_conf/lighttpd.conf



echo CREATING $DIR...
ssh  $USR@$SERVER "mkdir $DIR"
echo COPYING FILES...
scp -r ../wallet/* $USR@$SERVER:$DIR/
echo CREATING SYMBOLIC LINKS AND RESTARTING SERVER
ssh $USR@$SERVER "rm $WALLETLINK;ln -s $DIR $WALLETLINK;sudo rm $CONFLINK; sudo ln -s $CONFFILE $CONFLINK;sudo /etc/init.d/lighttpd restart";

