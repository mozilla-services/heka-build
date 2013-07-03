#!/bin/bash

command -v fpm >/dev/null 2>&1 || {
	echo >&2 "I require fpm but it's not installed.  Aborting."
	exit 1
}

if [ $1 != "rpm" -a $1 != "deb" -a $1 != "tarball" ]; then
	echo >&2 "usage: make_pkgs.sh [deb|rpm|tarball]"
	exit 1
fi

ROOT=tmp_pkg_root
mkdir -p $ROOT/usr/bin
mkdir -p $ROOT/etc
mkdir -p $ROOT/usr/share/man/man1
mkdir -p $ROOT/usr/share/man/man5
mkdir -p $1s
VERSION=`./bin/hekad -version`
cp bin/hekad $ROOT/usr/bin
cp bin/sbmgr $ROOT/usr/bin
cp bin/flood $ROOT/usr/bin
cp sample/hekad.toml $ROOT/etc/hekad.toml.sample
cp src/github.com/mozilla-services/heka/docs/build/man/hekad.1 $ROOT/usr/share/man/man1
cp src/github.com/mozilla-services/heka/docs/build/man/hekad.*.5 $ROOT/usr/share/man/man5
gzip $ROOT/usr/share/man/man1/hekad.1
gzip $ROOT/usr/share/man/man5/hekad.*
if [ $1 == "tarball" ]; then
	mv $ROOT hekad-$VERSION
	tar zcf hekad-$VERSION.tar.gz hekad-$VERSION
	mv hekad-$VERSION.tar.gz ./$1s/
	rm -fr hekad-$VERSION
else
	cd $ROOT
	fpm -s dir -t $1 -n "hekad" -v $VERSION --iteration ${ITERATION:-1} --license "MPLv2.0" --vendor Mozilla -m "<services-dev@mozilla.org>" --url "http://hekad.readthedocs.org" --description "High performance data gathering, analysis, monitoring, and reporting." .
	mv hekad*$VERSION-$ITERATION*.$1 ../$1s
	cd ..
	rm -fr $ROOT
fi
