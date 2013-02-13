#!/usr/bin/env python
from __future__ import print_function
from __future__ import with_statement

import json
import os.path
import sys


def main():
    scriptname = "register_mozsvc_plugins.py"
    fpath = "etc/plugin_packages.json"
    pkgs_key = "plugin_packages"
    pkg_path = "github.com/mozilla-services/heka-mozsvc-plugins"

    # default
    pkgs_data = {pkgs_key: [pkg_path]}

    if os.path.exists(fpath):
        with open(fpath) as pkgs_file:
            pkgs_file_blob = pkgs_file.read()
            try:
                pkgs_data = json.loads(pkgs_file_blob)
            except ValueError, e:
                print("{0}: Error parsing '{1}' JSON:".format(scriptname,
                        fpath))
                print("---> {0}".format(e))
                sys.exit(1)
            if pkgs_key not in pkgs_data:
                pkgs_data[pkgs_key] = [pkg_path]
            elif pkg_path not in pkgs_data[pkgs_key]:
                pkgs_data[pkgs_key].append(pkg_path)
            else:
                # it's in there, don't need to do anything
                sys.exit()

    if not os.path.exists('etc'):
        os.mkdir('etc')

    with open(fpath, 'w') as pkgs_file:
        pkg_json = json.dumps(pkgs_data)
        pkgs_file.write("{0}\n".format(pkg_json))


if __name__ == "__main__":
    main()
