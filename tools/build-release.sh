#!/bin/sh

set -e

BASEDIR=`pwd`
PACKAGES_DIR=packages

find -type d -name DEBIAN | rev | cut -d/ -f2- | rev | while read dir
do
    echo Building package on $dir
    cd $dir
    ./buildpackage
    echo Changing back to $BASEDIR
    cd $BASEDIR
done

find -name '*.deb' | while read p
do 
    mv -v $p $PACKAGES_DIR
done

echo done.
