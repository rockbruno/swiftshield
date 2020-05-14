SHELL = /bin/bash

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build
RELEASEBUILDDIR = $(BUILDDIR)/release
TEMPPRODUCTDIR = $(BUILDDIR)/_PRODUCT
PRODUCTDIR = $(RELEASEBUILDDIR)/_PRODUCT

.DEFAULT_GOAL = all

.PHONY: all
all: build

.PHONY: build
build:
	swift build \
		-c release \
		--build-path "$(BUILDDIR)"
	rm -rf "$(PRODUCTDIR)"
	rm -rf "$(TEMPPRODUCTDIR)"
	mkdir -p "$(TEMPPRODUCTDIR)"
	mkdir -p "$(TEMPPRODUCTDIR)/include/swiftshield"
	cp -a "$(RELEASEBUILDDIR)/." "$(TEMPPRODUCTDIR)/include/swiftshield"
	cp -a "$(TEMPPRODUCTDIR)/." "$(PRODUCTDIR)"
	rm -rf "$(TEMPPRODUCTDIR)"
	mkdir -p "$(PRODUCTDIR)/bin"
	rm -rf $(PRODUCTDIR)/include/swiftshield/*.build
	rm -rf $(PRODUCTDIR)/include/swiftshield/*.product
	rm -rf $(PRODUCTDIR)/include/swiftshield/ModuleCache
	rm -f "$(PRODUCTDIR)/include/swiftshield/swiftshield.swiftdoc"
	rm -f "$(PRODUCTDIR)/include/swiftshield/swiftshield.swiftmodule"
	mv "$(PRODUCTDIR)/include/swiftshield/swiftshield" "$(PRODUCTDIR)/bin"
	cp -a "$(REPODIR)/Sources/Csourcekitd/." "$(PRODUCTDIR)/include/swiftshield/Csourcekitd"
	rm -f "$(RELEASEBUILDDIR)/swiftshield"
	ln -s "$(PRODUCTDIR)/bin/swiftshield" "$(RELEASEBUILDDIR)/swiftshield"
	cp "$(REPODIR)/LICENSE" "$(PRODUCTDIR)/LICENSE"

.PHONY: package
package:
	rm -f "$(PRODUCTDIR)/swiftshield.zip"
	cd $(PRODUCTDIR) && zip -r ./swiftshield.zip ./
	echo "ZIP created at: $(PRODUCTDIR)/swiftshield.zip"

.PHONY: clean
clean:
	rm -rf "$(BUILDDIR)"

.PHONY: test
test:
	swift test --generate-linuxmain
	swift test

.PHONY: swiftshield
swiftshield:
	@echo "Oops, wrong folder! To test the example project, you should be inside the ExampleProject folder."