SHELL = /bin/bash

prefix ?= /usr/local
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build

.DEFAULT_GOAL = install
.PHONY: gnimag install uninstall clean

gnimag:
	@scripts/CopyResources.sh
	@swift build \
		-c release \
		-Xswiftc "-whole-module-optimization" \
		-Xswiftc "-Ounchecked" \
		-Xswiftc "-suppress-warnings" \
		--disable-sandbox \
		--build-path "$(BUILDDIR)"

install: gnimag
	@install -d "$(bindir)" "$(libdir)"
	@install "$(BUILDDIR)/release/gnimag" "$(bindir)"

uninstall:
	@scripts/CopyResources.sh clean
	@rm -rf "$(bindir)/gnimag"

clean:
	@scripts/CopyResources.sh clean
	@rm -rf $(BUILDDIR)