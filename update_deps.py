"""Script that reads a file to update package dependencies

This script reads a file formatted to indicate the project, whether the
project should be checked out, or fetched with go get, and the specific
changeset number.

Example package file::

    github.com/bitly/go-simplejson 477b2e70b12d

Two fields are present in a single line:

    repository changeset_hash

The changeset_hash can be a specific hash to checkout, or just the
branch name to always update to the latest version.

To run this script, designate a file to read. The Go workspace to
operate in should be set in the environ as GOPATH.

Example::

    python update_deps.py package_deps.txt

"""
from __future__ import print_function
import os
import subprocess
import sys

USAGE = "python update_deps.py PACKAGE_FILE.txt"


class Package(object):
    """A simple interface class describing a package to track

    An instance must have the attribute 'type' that is either bzr, git,
    or hg.

    """
    def __init__(self, host, repo_path, base_dir, changeset):
        """Initialize a Package based on a host, designated name, and
        starting with a designated base directory"""
        raise NotImplemented()

    def install(self):
        """Install the package so its available to Go"""
        raise NotImplemented()

    def needs_update(self):
        """Given a changeset, determine if an update is needed.

        :returns: Boolean indicating if the current version is
                  equivalent to the desired changeset.

        """
        raise NotImplemented()


class GitPackage(Package):
    type = "git"

    def __init__(self, host, repo_path, base_dir, changeset):
        self.base_dir = base_dir
        self.changeset = changeset

        if host == 'github.com':
            self.prefix = ""
            parts = repo_path.split('/', 2)
            if len(parts) > 2:
                user, project, sub_path = parts
            else:
                user, project, sub_path = parts[0], parts[1], ''
            self.repo = '%s/%s/%s' % (host, user, project)
            self.repo_clone = 'git@%s:%s/%s.git' % (host, user, project)
            self.sub_path = sub_path
        else:
            repo = '/'.join(host, repo_path)
            # Locate the base repo by the chunk that has the .git
            self.repo, self.sub_path = repo.split('.git')
            self.repo_clone = "http://%s.git" % self.repo

        self.repo_path = os.path.join(self.base_dir, self.repo)

    def install(self):
        exisiting_dir = True
        if not os.path.exists(self.repo_path):
            path_to_repo = self.repo_path.rsplit("/", 1)[0]
            run_command("mkdir -p %s" % path_to_repo)
            os.chdir(path_to_repo)
            print(run_command("git clone %s" % self.repo_clone)[1])
            exisiting_dir = False

        # Ensure we have the right revision
        os.chdir(self.repo_path)

        # Check to see there aren't local modifications
        if exisiting_dir and run_command("git diff")[1]:
            print("Warning: Local modifications detected in %s, "
                "skipping update." % self.repo)
            return
        run_command("git checkout -f %s" % self.changeset)

    def needs_update(self):
        if not os.path.exists(self.repo_path):
            return True

        os.chdir(self.repo_path)
        cur_version = run_command("git rev-parse HEAD")[1].strip()
        return cur_version != self.changeset


class BazaarPackage(Package):
    type = "bzr"

    def __init__(self, host, repo_path, base_dir, changeset):
        self.host = host
        self.base_dir = base_dir
        self.changeset = changeset

    def install(self):
        pass

    def needs_update(self):
        return False


class MercurialPackage(Package):
    type = "hg"

    def __init__(self, host, repo_path, base_dir, changeset):
        self.base_dir = base_dir
        self.changeset = changeset

        if host == "bitbucket.org":
            parts = repo_path.split('/', 2)
            if len(parts) > 2:
                user, project, sub_path = parts
            else:
                user, project, sub_path = parts[0], parts[1], ''
            self.repo = '%s/%s/%s' % (host, user, project)
            self.sub_path = sub_path
        else:
            repo = '/'.join(host, repo_path)
            # Locate the base repo by the chunk that has the .hg
            self.repo, self.sub_path = repo.split('.hg')

        self.repo_path = os.path.join(self.base_dir, self.repo)

    def install(self):
        if not os.path.exists(self.repo_path):
            run_command("mkdir -p %s" % self.repo_path)
            os.chdir(self.repo_path.split('/')[:-1])
            run_command("hg clone %s" % self.repo)

        # TODO: Make this work
        # Since we need a -r REV for a revision vs. branch with
        # Mercurial, we need to examine the branches and determine if
        # the changeset is a branch name first, and fetch if it is, or
        # update to the revision otherwise

    def needs_update(self):
        if not os.path.exists(self.repo_path):
            return True

        os.chdir(self.repo_path)
        cur_version = run_command("hg id -i")[1].strip()
        return cur_version != self.changeset


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


def parse_package_file(package_lines, base_dir):
    """Parses the contents of a package file

    Creates and returns a package instance.

    changeset may be None to indicate the latest should always be
    used.

    """
    packages = []
    for line in package_lines:
        repo, changeset = line.split(" ")

        # Split host from repository path
        host, path = repo.split("/", 1)

        if '.git' in repo or host == 'github.com':
            pkg = GitPackage(host, path, base_dir, changeset)
        elif '.bzr' in repo or host == 'launchpad.net':
            pkg = BazaarPackage(host, path, base_dir, changeset)
        elif '.hg' in repo or host == 'bitbucket.org':
            pkg = MercurialPackage(host, path, base_dir, changeset)
        packages.append(pkg)
    return packages


def main():
    if len(sys.argv) != 2:
        print(USAGE)
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

    here_dir = os.path.dirname(os.path.abspath(__file__))
    src_dir = os.path.join(here_dir, 'src')
    packages = parse_package_file(package_lines, src_dir)

    # Last sanity check to see that we have what we need
    cmds = locate_commands()
    for pkg in packages:
        if pkg.type not in cmds:
            raise Exception("Unable to find command to handle %s" % pkg["type"])

    # Locate the src directory and change to it
    os.chdir(src_dir)

    # Go through and update/checkout as needed
    for pkg in packages:
        if pkg.needs_update():
            # Save local location, and reset it after install
            pkg.install()
        os.chdir(src_dir)

if __name__ == "__main__":
    main()
