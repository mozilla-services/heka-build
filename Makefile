APPNAME = hekad
DEPS =
HERE = $(shell pwd)
BIN = $(HERE)/bin
GOBIN = $(HERE)/bin/go
GOCMD = LD_LIBRARY_PATH=${BIN} DYLD_LIBRARY_PATH=${BIN} GOPATH=$(HERE) $(GOBIN)
GOPATH = $GOPATH:$(HERE)

ifeq ($(MAKECMDGOALS),test-bench)
	BENCH = -bench .
endif

.PHONY: all build test clean-env clean gospec moz-plugins
.SILENT: test

all: build

clean-go:
	rm -rf bin/go build

clean-src:
	rm -rf src/*

clean-heka:
	rm -f bin/hekad bin/libsandbox.so

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

build/go:
	mkdir build
	cd build && \
		hg clone -u 8d71734a0cb0 https://code.google.com/p/go

$(GOBIN): build/go
	cd build/go/src && \
		./all.bash
	cp build/go/bin/go $(HERE)/bin/go

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

bin/hekad: pluginloader heka-source $(GOBIN)
	@python update_deps.py package_deps.txt
	@cd src && \
		$(GOCMD) install -ldflags="-r ./" github.com/mozilla-services/heka/hekad

hekad: sandbox bin/hekad

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

test: gomock gospec
	$(GOCMD) test -i github.com/mozilla-services/heka/pipeline
	$(GOCMD) test $(BENCH) github.com/mozilla-services/heka/pipeline
	$(GOCMD) test $(BENCH) github.com/mozilla-services/heka/message
	$(GOCMD) test $(BENCH) github.com/mozilla-services/heka/sandbox/lua

test-bench: test

test-all: test
	$(GOCMD) test -i github.com/mozilla-services/heka-mozsvc-plugins
	$(GOCMD) test github.com/mozilla-services/heka-mozsvc-plugins

pluginloader: heka-source
	./scripts/setup_pluginloader.py

rpms: moz-plugins build docs
	./scripts/make_pkgs.sh rpm

debs: moz-plugins build docs
	./scripts/make_pkgs.sh deb

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
