#!/usr/bin/env python

"""
Script that checks for reasonable defaults for GOROOT.

GOROOT *must* be defined for Heka to compile.

If GOROOT isn't defined try to give a useful suggestion.
"""

import os
import os.path
import sys
import re
import subprocess
from distutils.version import StrictVersion

REV_REGEX = re.compile(r"go version go(\d+\.\d+)")
HERE = os.getcwd()

VALID_GOROOTS = ['/usr/lib/go',
                 '/usr/local/go',
                 os.path.join(HERE, 'build', 'go')]

if len(sys.argv) > 1:
    hg_go = os.path.normpath('%s/build/go' % sys.argv[1])
    VALID_GOROOTS.append(hg_go)

GOROOT = os.getenv('GOROOT', None)


def find_goroot():
    """
    Check for possible Go paths using the ordered list of valid go
    roots
    """
    go_roots = {'valid': None, "invalid": None}
    for p in VALID_GOROOTS:
        go_bin = os.path.join(p, 'bin/go')
        if os.path.exists(p) and os.path.isfile(go_bin):
            if version_check(go_bin):
                if go_roots['valid'] is None:
                    go_roots['valid'] = p
            else:
                if go_roots['invalid'] is None:
                    go_roots['invalid'] = p

    if go_roots['valid']:
        return go_roots['valid']
    return ""

def version_check(go_bin):
    """
    Check that we're using at least go 1.1
    """
    cmd = [go_bin, 'version']
    version = subprocess.Popen(cmd, stdout=subprocess.PIPE).communicate()[0]
    match = REV_REGEX.match(version)
    goversion = match.groups()[0]
    return StrictVersion(goversion) >= StrictVersion("1.1")


if __name__ == "__main__":
    if not GOROOT:
        GOROOT = find_goroot()

    go_bin = os.path.join(GOROOT, 'bin/go')
    if os.path.isfile(go_bin) and version_check(go_bin):
        print GOROOT

