APPNAME = hekad
DEPS =
HERE = $(shell pwd)
BIN = $(HERE)/bin
GOBIN = $(HERE)/bin/go
GOCMD = GOPATH=$(HERE) $(GOBIN)
GOPATH = $GOPATH:$(HERE)


.PHONY: all build test clean-env clean gospec moz-plugins
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

build/go:
	mkdir build
	cd build && \
		hg clone -u 477b2e70b12d https://code.google.com/p/go

$(GOBIN): build/go
	cd build/go/src && \
		./all.bash
	cp build/go/bin/go $(HERE)/bin/go

src/github.com/mozilla-services/heka/README.md:
	mkdir -p src/github.com/mozilla-services
	cd src/github.com/mozilla-services && \
		git clone https://github.com/mozilla-services/heka.git

heka-source: src/github.com/mozilla-services/heka/README.md

bin/hekad: pluginloader heka-source $(GOBIN)
	@python update_deps.py package_deps.txt
	@cd src && \
		$(GOCMD) install github.com/mozilla-services/heka/hekad

hekad: bin/hekad

src/github.com/mozilla-services/heka-mozsvc-plugins/README.md:
	mkdir -p src/github.com/mozilla-services
	cd src/github.com/mozilla-services && \
		git clone https://github.com/mozilla-services/heka-mozsvc-plugins.git

moz-plugins-source: src/github.com/mozilla-services/heka-mozsvc-plugins/README.md

src/github.com/crankycoder/g2s:
	$(GOCMD) get github.com/crankycoder/g2s

g2s: src/github.com/crankycoder/g2s

moz-plugins: $(GOBIN) g2s moz-plugins-source

build: hekad

src/code.google.com/p/gomock/gomock:
	$(GOCMD) get code.google.com/p/gomock/gomock

gomock: src/code.google.com/p/gomock/gomock

src/github.com/rafrombrc/gospec/src/gospec:
	$(GOCMD) get github.com/rafrombrc/gospec/src/gospec

gospec: src/github.com/rafrombrc/gospec/src/gospec

test: gomock gospec
	$(GOCMD) test -i github.com/mozilla-services/heka/pipeline
	$(GOCMD) test github.com/mozilla-services/heka/pipeline
	$(GOCMD) test github.com/mozilla-services/heka/message

test-all: test
	$(GOCMD) test -i github.com/mozilla-services/heka-mozsvc-plugins
	$(GOCMD) test github.com/mozilla-services/heka-mozsvc-plugins

pluginloader: heka-source
	./scripts/setup_pluginloader.py

rpms: moz-plugins pluginloader build
	./scripts/make_pkgs.sh rpm

debs: moz-plugins pluginloader build
	./scripts/make_pkgs.sh deb

dev: heka-source
	cd src/github.com/mozilla-services/heka && \
	git config remote.origin.url git@github.com:mozilla-services/heka.git

dev-moz-plugins: moz-plugins
	cd src/github.com/mozilla-services/heka-mozsvc-plugins && \
	git config remote.origin.url git@github.com:mozilla-services/heka-mozsvc-plugins.git

