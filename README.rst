heka-build
==========

The heka build environment automatically sets up a complete Go
environment with the necessary packages installed to build/compile/test
the `heka <https://github.com/mozilla-services/heka/>`_ daemon.

Prerequisites
=============

heka requires the latest Golang tip at the moment, which will be
automatically downloaded and compiled. Compiling Go requires some C
tools, per the Go docs:

    The Go tool chain is written in C. To build it, you need a C
    compiler installed.

    On OS X, a C compiler is bundled in the command line tools for
    Xcode, and you don't need to install the whole Xcode to compile Go.
    If you have already installed Xcode 4.3+, you can install command
    line tools from the Components tab of the Downloads preferences
    panel. To verify you have a working compiler, just invoke gcc in a
    freshly created Terminal window, unless you see the "gcc: command
    not found" error, you are ready to go.

    On Ubuntu/Debian, use sudo apt-get install gcc libc6-dev. If you
    want to build 32-bit binaries on a 64-bit system you'll also need
    the libc6-dev-i386 package.

    On Windows, install gcc with MinGW. (Make sure you add its bin
    subdirectory to your PATH.)

If you already have a recent Go tip (from at least Nov 12th), you may
specify it using the environment variable GOBIN, and this step will be
skipped.

Installing
==========

Check out this repository, then run::

    make

The appropriate Go dependencies will be downloaded and installed, and
the hekad binary will be built.

Running Tests
=============

Run::

    make test

Appropriate test packages will be installed if needed and the tests
will be run.

Optional Mozilla Plugins
========================

Mozilla heka plugins may be installed by running::

    make moz-plugins
