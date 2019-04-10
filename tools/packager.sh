#!/bin/sh
set -e

    run_phpunit() {
        echo Running phpunit tests
        CURRENT=`pwd`
        cd "$1"
        phpunit --log-junit results.xml .
        cd "$CURRENT"
    }

    run_jshint() {
        # javascript tests
        if ! jshint --version
        then
            echo You need to install jshint.
            exit 1
        fi
        find "$1" -type f | while read f; do echo "Testing $f..."; jshint "$f" ; done
    }

    check_pot_files() {
        for file in `find -name '*.pot'`
        do
            if [ ! -z "`msgattrib --translated $file`" ]
            then
                echo You have translations on your template file $file. Aborting.
                exit 1
            fi
        done
    }

    get_git_revision() {
        GIT_REVISION=`git log . | head -n1 | cut -f2 -d' '`
        PKGDATE=`git show -s --format=%ci $GIT_REVISION`
        echo Last commit is $GIT_REVISION from $PKGDATE
    }

    get_git_branch() {
        if [ -z "$GIT_BRANCH" ]
        then
            GIT_BRANCH=`git branch | grep ^* | cut -f2 -d' '`
        fi
    }

    GIT=`git rev-parse --show-toplevel`

    if [ -z "$PACKAGE" -o -z "$DESCRIPTION" ]
    then
        echo "You need to define PACKAGE and DESCRIPTION"
        exit 1
    fi

    #if (! git status | grep 'working directory clean')
    if [ "x$WALLET_IGNORE_GIT_STATUS" = "x" ] 
		then
			if (! git status | grep 'working directory clean' )
    		then
        	echo "Unable to proceed. Uncommitted changes or working directory not clean."
        	exit 1
    	fi
		fi

    get_git_branch

    CURRENT_RELEASE=`cat $GIT/release`
    echo "Latest release is $CURRENT_RELEASE"

    get_git_revision

    echo Getting release file from last commit $GIT_REVISION
    git checkout $GIT_REVISION $GIT/release

    RELEASE=`cat $GIT/release`
    PKGVER="$RELEASE"b`git rev-list $GIT_REVISION | wc -l | sed 's/ //g'`
    PKGDIR=/tmp/${PACKAGE}_${GIT_REVISION}
    PKGFILE=${PACKAGE}_${PKGVER}_amd64.deb

    echo Restoring release file
    git checkout $GIT_BRANCH $GIT/release

    if [ "$RELEASE" != "$CURRENT_RELEASE" ]
    then
        echo "***"
        echo "*** WARNING"
        echo "*** This package didn't change since release $RELEASE"
        echo "***"
    fi

    echo "Creating debian package '$PACKAGE' version $PKGVER from git branch '$GIT_BRANCH' ..."

    # checks
    pre_build_hook
    
    # init package dir
    rm -rf $PKGDIR
    mkdir -v $PKGDIR

    # copy debian dir
    cp -r DEBIAN $PKGDIR
    
    # copy content
    copy_content $PKGDIR
 
    # package version
    echo "Package: $PACKAGE" >> $PKGDIR/DEBIAN/control
    echo "Description: $DESCRIPTION - Created from branch $GIT_BRANCH (commit $GIT_REVISION) on `date`" >> $PKGDIR/DEBIAN/control
    echo "Version: $PKGVER" >> $PKGDIR/DEBIAN/control

    # build package
    dpkg-deb -b -Zgzip $PKGDIR .
 
    # remove pkgdir
    echo "Removing $PKGDIR"
    rm -rf $PKGDIR

    # sign package if in staging or master branches
    if [ "$GIT_BRANCH" = "staging" -o "$GIT_BRANCH" = "master" -o "$SIGN_PACKAGES" = "yes" ]
    then
    echo "Signing $PKGFILE"
        if (! dpkg-sig --sign builder $PKGFILE)
        then
            echo "WARNING: Package signing is needed for staging and production environments!"
            echo "WARNING: You need to install dpkg-sig (apt-get install dpkg-sig) and setup your GPG keys (gpg --gen-key) to be able to sign packages."
        fi
    fi

