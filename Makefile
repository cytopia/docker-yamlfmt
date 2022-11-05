ifneq (,)
.error This Makefile requires GNU Make.
endif

# Ensure additional Makefiles are present
MAKEFILES = Makefile.docker Makefile.lint
$(MAKEFILES): URL=https://raw.githubusercontent.com/devilbox/makefiles/master/$(@)
$(MAKEFILES):
	@if ! (curl --fail -sS -o $(@) $(URL) || wget -O $(@) $(URL)); then \
		echo "Error, curl or wget required."; \
		echo "Exiting."; \
		false; \
	fi
include $(MAKEFILES)

# Set default Target
.DEFAULT_GOAL := help


# -------------------------------------------------------------------------------------------------
# Default configuration
# -------------------------------------------------------------------------------------------------
# Own vars
TAG        = latest

# Makefile.docker overwrites
NAME       = yamlfmt
VERSION    = latest
IMAGE      = cytopia/yamlfmt
FLAVOUR    = latest
FILE       = Dockerfile
DIR        = Dockerfiles

# Building from master branch: Tag == 'latest'
ifeq ($(strip $(TAG)),latest)
	ifeq ($(strip $(VERSION)),latest)
		DOCKER_TAG = $(FLAVOUR)
	else
		ifeq ($(strip $(FLAVOUR)),latest)
			DOCKER_TAG = $(VERSION)
		else
			DOCKER_TAG = $(FLAVOUR)-$(VERSION)
		endif
	endif
# Building from any other branch or tag: Tag == '<REF>'
else
	ifeq ($(strip $(FLAVOUR)),latest)
		DOCKER_TAG = $(VERSION)-$(TAG)
	else
		DOCKER_TAG = $(FLAVOUR)-$(VERSION)-$(TAG)
	endif
endif

# Makefile.lint overwrites
FL_IGNORES  = .git/,.github/
SC_IGNORES  = .git/,.github/
JL_IGNORES  = .git/,.github/


# -------------------------------------------------------------------------------------------------
#  Default Target
# -------------------------------------------------------------------------------------------------
.PHONY: help
help:
	@echo "lint                                     Lint project files and repository"
	@echo
	@echo "build [ARCH=...] [TAG=...]               Build Docker image"
	@echo "rebuild [ARCH=...] [TAG=...]             Build Docker image without cache"
	@echo "push [ARCH=...] [TAG=...]                Push Docker image to Docker hub"
	@echo
	@echo "manifest-create [ARCHES=...] [TAG=...]   Create multi-arch manifest"
	@echo "manifest-push [TAG=...]                  Push multi-arch manifest"
	@echo
	@echo "test [ARCH=...]                          Test built Docker image"
	@echo


# -------------------------------------------------------------------------------------------------
#  Docker Targets
# -------------------------------------------------------------------------------------------------
.PHONY: build
build: ARGS=--build-arg VERSION=$(VERSION)
build: docker-arch-build

.PHONY: rebuild
rebuild: ARGS=--build-arg VERSION=$(VERSION)
rebuild: docker-arch-rebuild

.PHONY: push
push: docker-arch-push


# -------------------------------------------------------------------------------------------------
#  Manifest Targets
# -------------------------------------------------------------------------------------------------
.PHONY: manifest-create
manifest-create: docker-manifest-create

.PHONY: manifest-push
manifest-push: docker-manifest-push


# -------------------------------------------------------------------------------------------------
#  Test Targets
# -------------------------------------------------------------------------------------------------
.PHONY: test
test: _test-run-ok
test: _test-run-fail

.PHONY: _test-run-ok
_test-run-ok:
	@echo "------------------------------------------------------------"
	@echo "- Testing valid yaml files"
	@echo "------------------------------------------------------------"
	@if ! docker run --rm --platform $(ARCH) -v $(CURRENT_DIR)/tests/ok:/data $(IMAGE):$(DOCKER_TAG) ok1.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if ! docker run --rm --platform $(ARCH) -v $(CURRENT_DIR)/tests/ok:/data $(IMAGE):$(DOCKER_TAG) ok2.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if ! docker run --rm --platform $(ARCH) -v $(CURRENT_DIR)/tests/ok:/data $(IMAGE):$(DOCKER_TAG) '*.yml' ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	echo "Success";

.PHONY: _test-run-fail
_test-run-fail:
	@echo "------------------------------------------------------------"
	@echo "- Testing invalid yaml files"
	@echo "------------------------------------------------------------"
	@if docker run --rm --platform $(ARCH) -v $(CURRENT_DIR)/tests/fail:/data $(IMAGE):$(DOCKER_TAG) fail1.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if docker run --rm --platform $(ARCH) -v $(CURRENT_DIR)/tests/fail:/data $(IMAGE):$(DOCKER_TAG) fail2.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if docker run --rm --platform $(ARCH) -v $(CURRENT_DIR)/tests/fail:/data $(IMAGE):$(DOCKER_TAG) notexisting.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if docker run --rm --platform $(ARCH) -v $(CURRENT_DIR)/tests/fail:/data $(IMAGE):$(DOCKER_TAG) '*.yml' ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	echo "Success";
