#!/bin/bash

command -v fpm >/dev/null 2>&1 || {
	echo >&2 "I require fpm but it's not installed.  Aborting."
	exit 1
}

if [ $1 != "rpm" -a $1 != "deb" ]; then
	echo >&2 "usage: make_pkgs.sh [deb|rpm]"
	exit 1
fi

ROOT=tmp_pkg_root
mkdir -p $ROOT/usr/bin
mkdir -p $ROOT/etc
mkdir -p $1s
VERSION=`./bin/hekad -version`
cp bin/hekad $ROOT/usr/bin
cp sample/hekad.json $ROOT/etc/hekad.json.sample
cd $ROOT
fpm -s dir -t $1 -n "hekad" -v $VERSION --iteration ${ITERATION:-1} .
mv hekad*$VERSION-$ITERATION*.$1 ../$1s
cd ..
rm -fr tmp_pkg_root
