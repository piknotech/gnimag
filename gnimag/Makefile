SHELL = /bin/bash

prefix ?= /usr/local
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
srcdir = Sources

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build
SOURCES = $(wildcard $(srcdir)/**/*.swift)

.DEFAULT_GOAL = all

.PHONY: all
all: gnimag

gnimag: $(SOURCES)
	@accio install
	@cp -a Dependencies/macOS/ .build
	@xcodebuild \
		-configuration release \
		-scheme All \
		CONFIGURATION_BUILD_DIR="$(BUILDDIR)" \
		BUILT_PRODUCTS_DIR="$(BUILDDIR)"

.PHONY: install
install: gnimag
	@install -d "$(bindir)" "$(libdir)"
	@install "$(BUILDDIR)/release/gnimag" "$(bindir)"

.PHONY: uninstall
uninstall:
	@rm -rf "$(bindir)/gnimag"

.PHONY: clean
distclean:
	@rm -f $(BUILDDIR)/release

.PHONY: clean
clean: distclean
	@rm -rf $(BUILDDIR)