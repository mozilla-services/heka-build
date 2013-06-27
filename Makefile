APPNAME = hekad
DEPS =
HERE = $(shell pwd)
BIN = $(HERE)/bin

HGBIN = $(HERE)/pythonVE/bin/hg

CHECK_GOROOT_CMD = python scripts/check_goroot.py
GOROOT = $(shell $(CHECK_GOROOT_CMD))
ifeq ($(GOROOT),)
    $(error "Can't find working Go installation. Either install Go 1.1 or greater, or set GOROOT if you already have a working Go 1.1 or greater installation in a non-standard location")
endif

GOBIN = $(GOROOT)/bin/go
GOCMD = GOROOT=$(GOROOT) GOPATH=$(HERE) $(GOBIN)
GOPATH = $GOPATH:$(HERE)


ifeq ($(MAKECMDGOALS),test-bench)
	BENCH = -bench .
endif

.PHONY: all build test clean-env clean gospec moz-plugins check_goroot
.SILENT: test
 
all: build

clean-go:
	rm -rf bin/go build

clean-src:
	rm -rf src/*

clean-heka:
	rm -f bin/hekad

clean-all: clean-go clean-src clean-heka

clean: clean-heka

$(HERE)/heka-docs:
	git clone https://github.com/mozilla-services/heka-docs.git && \
	cd heka-docs && \
	git submodule update --init --recursive

$(HERE)/virtualenv:
	curl -O https://pypi.python.org/packages/source/v/virtualenv/virtualenv-1.9.1.tar.gz
	tar xzvf virtualenv-1.9.1.tar.gz
	mv virtualenv-1.9.1 virtualenv

$(HERE)/pythonVE: $(HERE)/virtualenv
	cd virtualenv && \
	python virtualenv.py ../pythonVE

$(HERE)/pythonVE/bin/sphinx-build: $(HERE)/pythonVE
	pythonVE/bin/pip install Sphinx

docs: $(HERE)/heka-docs $(HERE)/pythonVE/bin/sphinx-build bin/hekad
	cd heka-docs && \
		make html SPHINXBUILD=$(HERE)/pythonVE/bin/sphinx-build
	cd src/github.com/mozilla-services/heka/docs && \
		make html SPHINXBUILD=$(HERE)/pythonVE/bin/sphinx-build && \
		make man SPHINXBUILD=$(HERE)/pythonVE/bin/sphinx-build

sandbox: heka-source
	mkdir -p release
	cd release && cmake .. && make

src/github.com/mozilla-services/heka/README.md:
	mkdir -p src/github.com/mozilla-services
	cd src/github.com/mozilla-services && \
		git clone https://github.com/mozilla-services/heka.git && \
		cd heka && \
		git submodule update --init --recursive

heka-source: src/github.com/mozilla-services/heka/README.md

bin/hekad: pluginloader heka-source $(HERE)/pythonVE
	GOPATH=$GOPATH PATH="$(HERE)/pythonVE/bin:$(PATH)" python scripts/update_deps.py package_deps.txt
	@cd src && \
		$(GOCMD) install -ldflags="-linkmode=external"  github.com/mozilla-services/heka/cmd/hekad

hekad: sandbox bin/hekad

bin/flood:
	$(GOCMD) install github.com/mozilla-services/heka/cmd/flood

flood: bin/flood

bin/sbmgr:
	$(GOCMD) install github.com/mozilla-services/heka/cmd/sbmgr

sbmgr: bin/sbmgr

bin/sbmgrload:
	$(GOCMD) install github.com/mozilla-services/heka/cmd/sbmgrload

sbmgrload: bin/sbmgrload

src/github.com/mozilla-services/heka-mozsvc-plugins/README.md:
	mkdir -p src/github.com/mozilla-services
	cd src/github.com/mozilla-services && \
		git clone https://github.com/mozilla-services/heka-mozsvc-plugins.git

moz-plugins-source: src/github.com/mozilla-services/heka-mozsvc-plugins/README.md

src/github.com/crankycoder/g2s:
	$(GOCMD) get github.com/crankycoder/g2s

g2s: src/github.com/crankycoder/g2s

moz-plugins: $(GOBIN) g2s moz-plugins-source
	./scripts/register_mozsvc_plugins.py

build: hekad

src/code.google.com/p/gomock/gomock:
	$(GOCMD) get code.google.com/p/gomock/gomock

bin/mockgen:
	$(GOCMD) install code.google.com/p/gomock/mockgen

gomock: src/code.google.com/p/gomock/gomock bin/mockgen

src/github.com/rafrombrc/gospec/src/gospec:
	$(GOCMD) get github.com/rafrombrc/gospec/src/gospec

gospec: src/github.com/rafrombrc/gospec/src/gospec

test: hekad gomock gospec
	$(GOCMD) test -i github.com/mozilla-services/heka/pipeline
	$(GOCMD) test -ldflags="-linkmode=external" $(BENCH) github.com/mozilla-services/heka/pipeline
	$(GOCMD) test -ldflags="-linkmode=external" $(BENCH) github.com/mozilla-services/heka/message
	$(GOCMD) test -ldflags="-linkmode=external" $(BENCH) github.com/mozilla-services/heka/sandbox/lua

test-bench: test

test-all: test
	$(GOCMD) test -i github.com/mozilla-services/heka-mozsvc-plugins
	$(GOCMD) test github.com/mozilla-services/heka-mozsvc-plugins

pluginloader: heka-source
	./scripts/setup_pluginloader.py

rpms: moz-plugins build docs sbmgr flood
	./scripts/make_pkgs.sh rpm

debs: moz-plugins build docs sbmgr flood
	./scripts/make_pkgs.sh deb

osx: build docs
	mkdir -p osxproto/bin
	mkdir -p osxproto/share/man/man1
	mkdir -p osxproto/share/man/man5
	cp bin/hekad osxproto/bin/
	cp src/github.com/mozilla-services/heka/docs/build/man/*.1 osxproto/share/man/man1/
	cp src/github.com/mozilla-services/heka/docs/build/man/*.5 osxproto/share/man/man5/

dev: heka-source
	cd src/github.com/mozilla-services/heka && \
	git config remote.origin.url git@github.com:mozilla-services/heka.git && \
	git checkout dev && \
	git submodule update --init --recursive; \
	cd ../../../..; \
	if [ -e src/github.com/mozilla-services/heka-mozsvc-plugins ]; \
	then \
	    cd src/github.com/mozilla-services/heka-mozsvc-plugins && \
	    git config remote.origin.url git@github.com:mozilla-services/heka-mozsvc-plugins.git && \
	    git checkout dev && \
	    git submodule update --init --recursive; \
	fi
	if [ -e heka-docs ]; \
	then \
		cd heka-docs && \
		git config remote.origin.url git@github.com:mozilla-services/heka-docs.git && \
		git checkout dev && \
		git submodule update --init --recursive; \
	fi

undev: heka-source
	cd src/github.com/mozilla-services/heka && \
	git config remote.origin.url https://github.com/mozilla-services/heka.git && \
	git checkout master; \
	cd ../../../..; \
	if [ -e src/github.com/mozilla-services/heka-mozsvc-plugins ]; \
	then \
	    cd src/github.com/mozilla-services/heka-mozsvc-plugins && \
	    git config remote.origin.url https://github.com/mozilla-services/heka-mozsvc-plugins.git && \
	    git checkout master; \
	fi
	if [ -e heka-docs ]; \
	then \
		cd heka-docs && \
		git config remote.origin.url https://github.com/mozilla-services/heka-docs.git && \
		git checkout master; \
	fi

FORCE:
