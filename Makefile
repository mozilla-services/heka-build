APPNAME = hekad
DEPS =
HERE = $(shell pwd)
BIN = $(HERE)/bin
GOBIN = $(HERE)/bin/go
GOCMD = GOPATH=$(HERE) $(GOBIN)
GOPATH = $GOPATH:$(HERE)

BUILD_DIRS = bin/go build src/*


.PHONY: all build test clean-env clean gospec moz-plugins
.SILENT: test

all: build

clean-env:
	rm -rf $(BUILD_DIRS)

clean: clean-env

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

src/github.com/mozilla-services/heka/README.md: src/github.com/bitly/go-simplejson src/github.com/rafrombrc/go-notify src/github.com/ugorji/go-msgpack
	cd src && \
	mkdir -p github.com/mozilla-services && \
	cd github.com/mozilla-services && \
	git clone git@github.com:mozilla-services/heka.git
	cd src && \
	$(GOCMD) install github.com/mozilla-services/heka/hekad

src/github.com/mozilla-services/heka-mozsvc-plugins/README.md:
	cd src/github.com/mozilla-services && \
	git clone git@github.com:mozilla-services/heka-mozsvc-plugins.git

moz-plugins: src/github.com/mozilla-services/heka-mozsvc-plugins/README.md

build: $(GOBIN) src/github.com/mozilla-services/heka/README.md

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
