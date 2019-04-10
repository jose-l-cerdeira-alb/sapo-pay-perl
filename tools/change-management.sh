#!/bin/sh

after=\{2.weeks.ago\}

git log --after=$after | grep Author: | sort -u | cut -f2 -d\< | cut -f1 -d\> | while read author
do
    echo
    echo "Changes for author $author since $after"
    git --no-pager log --oneline --after=$after --author=$author
done
