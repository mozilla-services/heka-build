APPNAME = hekad
DEPS =
HERE = $(shell pwd)
BIN = $(HERE)/bin
GOBIN = $(HERE)/bin/go
GOCMD = GOPATH=$(HERE) $(GOBIN)
GOPATH = $GOPATH:$(HERE)

GO_BUILD_DIRS = bin/go build


.PHONY: all build test clean-env clean gospec moz-plugins
.SILENT: test

all: build

clean-go:
	rm -rf $(BUILD_DIRS)

clean-heka:
	rm -fr src/*
	rm bin/hekad

clean: clean-go clean-heka

build/go:
	mkdir build
	cd build && \
		hg clone -u 477b2e70b12d https://code.google.com/p/go

$(GOBIN): build/go
	cd build/go/src && \
		./all.bash
	cp build/go/bin/go $(HERE)/bin/go

src/github.com/bitly/go-simplejson:
	$(GOCMD) get github.com/bitly/go-simplejson

src/github.com/rafrombrc/go-notify:
	$(GOCMD) get github.com/rafrombrc/go-notify

src/github.com/ugorji/go-msgpack:
	$(GOCMD) get github.com/ugorji/go-msgpack

src/github.com/mozilla-services/heka/README.md:
	mkdir -p src/github.com/mozilla-services
	cd src/github.com/mozilla-services && \
		git clone https://github.com/mozilla-services/heka.git

bin/hekad: src/github.com/mozilla-services/heka/README.md $(GOBIN) src/github.com/bitly/go-simplejson src/github.com/rafrombrc/go-notify src/github.com/ugorji/go-msgpack
	cd src && \
		$(GOCMD) install github.com/mozilla-services/heka/hekad

hekad: bin/hekad

src/github.com/mozilla-services/heka-mozsvc-plugins/README.md:
	mkdir -p src/github.com/mozilla-services
	cd src/github.com/mozilla-services && \
		git clone https://github.com/mozilla-services/heka-mozsvc-plugins.git

src/github.com/crankycoder/g2s:
	$(GOCMD) get github.com/crankycoder/g2s

g2s: src/github.com/crankycoder/g2s

moz-plugins: g2s src/github.com/mozilla-services/heka-mozsvc-plugins/README.md

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

src/github.com/mozilla-services/heka/hekad/plugin_loader.go: src/github.com/mozilla-services/heka/README.md
	cd src/github.com/mozilla-services/heka/hekad && \
		cp plugin_loader.go.in plugin_loader.go
	rm -f bin/hekad

pluginloader: src/github.com/mozilla-services/heka/hekad/plugin_loader.go

rpms: pluginloader moz-plugins build
	./make_rpms.sh

dev: src/github.com/mozilla-services/heka/README.md
	cd src/github.com/mozilla-services/heka && \
	git config remote.origin.url git@github.com:mozilla-services/heka.git

dev-moz-plugins: moz-plugins
	cd src/github.com/mozilla-services/heka-mozsvc-plugins && \
	git config remote.origin.url git@github.com:mozilla-services/heka-mozsvc-plugins.git

