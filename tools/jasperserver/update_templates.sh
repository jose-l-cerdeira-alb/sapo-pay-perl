#!/bin/sh

set -e

HOST=dev.wallet.pt
TMPDIR="/tmp"
DIRNAME="jasper_dev_export"
ZIPNAME="jasper_dev_export.zip"
GITDIR=`git rev-parse --show-toplevel`

echo "### EXPORTING JASPERSERVER DATA ###"
echo
ssh $HOST "rm -f ~/$ZIPNAME ; /servers/jasperreports-server-install/buildomatic/js-export.sh --everything --output-zip $ZIPNAME"
echo "Done."
echo

echo "### GET THE FILE AND UNZIP IT ###"
echo
scp $HOST:$ZIPNAME $TMPDIR/
rm -rf $TMPDIR/$DIRNAME
mkdir -p $TMPDIR/$DIRNAME
unzip -q $TMPDIR/$ZIPNAME -d $TMPDIR/$DIRNAME
echo "Done."
echo

echo "### DELETE USER DATA ###"
echo
rm -rf $TMPDIR/$DIRNAME/index.xml $TMPDIR/$DIRNAME/users/
echo "Done."
echo

echo "### DELETE GENERATED REPORTS ###"
echo
find $TMPDIR/$DIRNAME/resources/ -wholename '*/gerados/*' -type d -print0 | xargs -0 rm -rf
echo "Done."
echo

echo "### COPYING FILES TO GIT ###"
cp -r $TMPDIR/$DIRNAME/* -t $GITDIR/backend/reporting/jasper/jasper-server/
echo "Done."
echo

echo "### CLEANING UP ###"
echo
rm -f $TMPDIR/$ZIPNAME
rm -rf $TMPDIR/$DIRNAME/
echo "Done."
echo
