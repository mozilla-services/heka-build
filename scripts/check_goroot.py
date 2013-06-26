#!/usr/bin/env python

"""
Script that checks for reasonable defaults for GOROOT
"""

import os
import sys

VALID_GOROOTS = ['/usr/lib/go',
                 '/usr/local/go',
                 os.path.normpath('%s/build/go' % sys.argv[1])]

GOROOT = os.getenv('GOROOT', None)


def guess_goroot():
    for p in VALID_GOROOTS:
        if os.path.exists(p):
            print "GOROOT should probably be set to this: [%s]" % p
            break

if not GOROOT:
    print "GOROOT is not set"
    guess_goroot()
    sys.exit(1)

if os.path.exists(GOROOT):
    go_bin = os.path.join(GOROOT, 'bin/go')
    if os.path.isfile(go_bin):
        sys.exit(0)

guess_goroot()

sys.exit(1)
