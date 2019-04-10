#!/bin/sh

set -e

if [ -z "$1" ]
then
    echo "No previous commit given."
    exit 1
fi

schema_dir=db/flyway/sql

branch=`git branch | grep \* | cut -f2 -d' ' | tr -s '/' '_'`

find -name DEBIAN -type d | sed 's/\/DEBIAN//' | while read package_dir 
do
    name=`basename $package_dir`
    filename=`cat $package_dir/buildpackage | grep PACKAGE\= | cut -f2 -d\=`_${branch}_${1}.diff
    echo "Generating diff from $1 for $name on $filename"
    git diff $1..HEAD $package_dir > diffs/$filename
    if [ ! -s diffs/$filename ]
    then
        echo "Removing empty diff $filename"
        rm -v diffs/$filename
    fi
done

echo
find -name "*_${branch}_${1}.diff"
