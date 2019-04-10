#!/bin/sh
set -e

REV_LAST_RELEASE_BUMP=`git log -n 1 release | grep ^commit | tail -n1 | cut -f2 -d\ `
git log --stat $REV_LAST_RELEASE_BUMP..

