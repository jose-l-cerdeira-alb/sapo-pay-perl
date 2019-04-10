#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

find $DIR/../ -name 'phpunit.xml' -wholename '*unittest*/phpunit.xml' | while read xml
do
    testdir=`dirname "$xml"`
    pdir=`pwd`
    cd $testdir
    phpunit .
    cd $pdir
done
