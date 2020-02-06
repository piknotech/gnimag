SHELL = /bin/bash

prefix ?= /usr/local
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
srcdir = Sources

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build
SOURCES = $(wildcard $(srcdir)/**/*.swift)

.DEFAULT_GOAL = install

gnimag: $(SOURCES)
	@swift build \
		-c release \
		-Xswiftc "-whole-module-optimization" \
		-Xswiftc "-Ounchecked" \
		--disable-sandbox \
		--build-path "$(BUILDDIR)"

install: gnimag
	@install -d "$(bindir)" "$(libdir)"
	@install "$(BUILDDIR)/release/gnimag" "$(bindir)"

uninstall:
	@rm -rf "$(bindir)/gnimag"

clean:
	@rm -rf $(BUILDDIR)