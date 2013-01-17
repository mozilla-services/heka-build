"""Script that reads a file to update package dependencies

This script reads a file formatted to indicate the project, whether the
project should be checked out, or fetched with go get, and the specific
changeset number.

Example package file::

    github.com/bitly/go-simplejson 477b2e70b12d

Two fields are present in a single line:

    repository checkout_flag changeset_hash

The changeset_hash can be left off, in which case this will always
attempt to update the code every time its run. The checkout_flag must
be either a 0 or 1 to indicate if the repo should be checked out.

Checking out repositories that are sub-directories is not supported.

To run this script, designate a file to read. The Go workspace to
operate in should be set in the environ as GOPATH.

Example::

    python update_deps.py package_deps.txt

"""
from __future__ import print_function
import os
import subprocess
import sys


def run_command(command, *args):
    """Runs a command until completed and return error code and output"""
    p = subprocess.Popen(command + " " + " ".join(args),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, error = p.communicate()
    return error, output


def locate_commands():
    """Locates system commands such as git/hg/svn/bzr"""
    command_hash = {}
    for cmd in ["git", "svn", "hg", "bzr"]:
        wcmd = run_command("which %s" % cmd)[1]
        if wcmd:
            command_hash[cmd] = wcmd.strip()
    return command_hash


def main():
    if len(sys.argv) < 2:
        print("No configuration file specified.")
        return
    gopath = os.environ.get('GOPATH')
    if not gopath:
        print("No GOPATH environment variable has been set.")
        return
    conf_file = sys.argv[1]
    if not os.path.exists(conf_file):
        print("Config file not found:", conf_file)
        return

    with open(conf_file, 'r') as f:
        package_lines = [x.strip() for x in f.readlines() if x.strip()]

    print(package_lines)

# main()
