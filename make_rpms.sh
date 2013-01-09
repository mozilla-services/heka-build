#!/bin/bash

command -v fpm >/dev/null 2>&1 || {
	echo >&2 "I require fpm but it's not installed.  Aborting."
	exit 1
}

mkdir -p tmp_rpm_root/usr/bin
mkdir -p rpms
VERSION=`./bin/hekad -version`
cp bin/hekad tmp_rpm_root/usr/bin
cd tmp_rpm_root
fpm -s dir -t rpm -n "hekad" -v $VERSION --iteration ${ITERATION:-1} usr
mv hekad-*.rpm ../rpms
cd ..
rm -fr tmp_rpm_root