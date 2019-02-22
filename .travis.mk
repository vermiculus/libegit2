EMAKE_SHA1       ?= 5bc70de1b562c1e5196e10a75df2a89f2e016de9
PACKAGE_BASENAME := libgit

emake.mk:
	wget "https://raw.githubusercontent.com/vermiculus/emake.el/$(EMAKE_SHA1)/emake.mk"

-include emake.mk

libgit2:                        ## pull down libgit2
	git submodule init
	git submodule update

build/libegit2.so: libgit2      ## build the module
	mkdir -p build
	cd build && cmake .. -DCMAKE_BUILD_TYPE=Debug && make

test: EMACS_ARGS += -l libgit.el
test: build/libegit2.so test-ert ## run tests

clean:                          ## removes build directories
	rm -rf build/ libgit2/

info: emake.mk
	$(info EMACS_VERSION=$(EMACS_VERSION))
	$(info EMAKE_SHA1=$(EMAKE_SHA1))
	$(info CI=$(CI))
	$(info TRAVIS_OS_NAME=$(TRAVIS_OS_NAME))
	$(info EMAKE_WORKDIR=$(EMAKE_WORKDIR))
	$(info EMAKE_USE_EVM=$(EMAKE_USE_EVM))
	$(info EMACS_ARGS=$(EMACS_ARGS))
	$(info PACKAGE_BASENAME=$(PACKAGE_BASENAME))
	$(info PACKAGE_FILE=$(PACKAGE_FILE))
	$(info PACKAGE_LISP=$(PACKAGE_LISP))
	$(info PACKAGE_TESTS=$(PACKAGE_TESTS))
	$(info PACKAGE_ARCHIVES=$(PACKAGE_ARCHIVES))
	$(info PACKAGE_TEST_ARCHIVES=$(PACKAGE_TEST_ARCHIVES))
	$(info EMAKE=$(EMAKE))
	$(info CURL=$(CURL))
	cmake --version
	cc --version

setup: emacs-with-modules #update-cmake

ifeq ($(TRAVIS_OS_NAME),osx)
export EMACS_CONFIGURE_ARGS := --with-ns --with-modules
endif

emacs-with-modules: SHELL := /bin/bash
emacs-with-modules:
	bash -e <(curl -fsSkL 'https://raw.githubusercontent.com/vermiculus/emake.el/$(EMAKE_SHA1)/install-emacs')
update-cmake:
	wget 'https://cmake.org/files/v3.13/cmake-3.13.4-Linux-x86_64.tar.gz'
	tar xf cmake-3.13.4-Linux-x86_64.tar.gz
