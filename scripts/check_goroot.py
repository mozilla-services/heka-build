#!/usr/bin/env python

"""
Script that checks for reasonable defaults for GOROOT.

GOROOT *must* be defined for Heka to compile.

If GOROOT isn't defined try to give a useful suggestion.
"""

import os
import sys
import re
import subprocess


REV_REGEX = re.compile(r"go version go(\S+) ")

VALID_GOROOTS = ['/usr/lib/go',
                 '/usr/local/go',
                 ]

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
        msg = "Error: GOROOT should be set to this: [%s]" % go_roots['valid']
    elif go_roots['invalid']:
        msg = """Error: No valid GOROOT could be found.
An old version of Go was found here: [%s]""" % go_roots['invalid']
    else:
        msg = """Error: Can't find any version of Go installed.
Try installing from a package from https://code.google.com/p/go/downloads/"""

    print msg
    return go_roots

def version_check(go_bin):
    """
    Check that we're using at least go 1.1
    """
    cmd = '%s version' % go_bin
    version = subprocess.check_output(cmd, shell=True).strip()
    match = REV_REGEX.match(version)
    groups = match.groups()
    revision_parts = [int(x) for x in groups[0].split('.')]

    major = revision_parts[0]
    minor = revision_parts[1]

    return float("%d.%d" % (major, minor)) >= 1.1


if __name__ == "__main__":
    if not GOROOT:
        print "Error: GOROOT is not set"
        find_goroot()
        sys.exit(1)

    go_bin = os.path.join(GOROOT, 'bin/go')
    if os.path.isfile(go_bin) and version_check(go_bin):
        sys.exit(0)

    find_goroot()
    sys.exit(1)

