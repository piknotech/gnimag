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
	@./CopyResources.sh
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
	@./CopyResources.sh clean
	@rm -rf "$(bindir)/gnimag"

clean:
	@./CopyResources.sh clean
	@rm -rf $(BUILDDIR)