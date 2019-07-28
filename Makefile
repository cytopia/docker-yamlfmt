ifneq (,)
.error This Makefile requires GNU Make.
endif

.PHONY: build rebuild lint test _test-run-ok _test-run-fail tag pull login push enter

CURRENT_DIR = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

DIR = .
FILE = Dockerfile
IMAGE = cytopia/yamlfmt
TAG = latest

build:
	docker build --build-arg VERSION=$(TAG) -t $(IMAGE) -f $(DIR)/$(FILE) $(DIR)

rebuild: pull
	docker build --no-cache --build-arg VERSION=$(TAG) -t $(IMAGE) -f $(DIR)/$(FILE) $(DIR)

lint:
	@docker run --rm -v $(CURRENT_DIR):/data cytopia/file-lint file-cr --text --ignore '.git/,.github/,tests/' --path .
	@docker run --rm -v $(CURRENT_DIR):/data cytopia/file-lint file-crlf --text --ignore '.git/,.github/,tests/' --path .
	@docker run --rm -v $(CURRENT_DIR):/data cytopia/file-lint file-trailing-single-newline --text --ignore '.git/,.github/,tests/' --path .
	@docker run --rm -v $(CURRENT_DIR):/data cytopia/file-lint file-trailing-space --text --ignore '.git/,.github/,tests/' --path .
	@docker run --rm -v $(CURRENT_DIR):/data cytopia/file-lint file-utf8 --text --ignore '.git/,.github/,tests/' --path .
	@docker run --rm -v $(CURRENT_DIR):/data cytopia/file-lint file-utf8-bom --text --ignore '.git/,.github/,tests/' --path .

test:
	@$(MAKE) --no-print-directory _test-run-ok
	@$(MAKE) --no-print-directory _test-run-fail

_test-run-ok:
	@echo "------------------------------------------------------------"
	@echo "- Testing valid yaml files"
	@echo "------------------------------------------------------------"
	@if ! docker run --rm -v $(CURRENT_DIR)/tests/ok:/data $(IMAGE) ok1.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if ! docker run --rm -v $(CURRENT_DIR)/tests/ok:/data $(IMAGE) ok2.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if ! docker run --rm -v $(CURRENT_DIR)/tests/ok:/data $(IMAGE) '*.yml' ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	echo "Success";

_test-run-fail:
	@echo "------------------------------------------------------------"
	@echo "- Testing invalid yaml files"
	@echo "------------------------------------------------------------"
	@if docker run --rm -v $(CURRENT_DIR)/tests/fail:/data $(IMAGE) fail1.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if docker run --rm -v $(CURRENT_DIR)/tests/fail:/data $(IMAGE) fail2.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if docker run --rm -v $(CURRENT_DIR)/tests/fail:/data $(IMAGE) notexisting.yml ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	if docker run --rm -v $(CURRENT_DIR)/tests/fail:/data $(IMAGE) '*.yml' ; then \
		echo "Failed"; \
		exit 1; \
	fi; \
	echo "Success";

tag:
	docker tag $(IMAGE) $(IMAGE):$(TAG)

pull:
	@grep -E '^\s*FROM' Dockerfile \
		| sed -e 's/^FROM//g' -e 's/[[:space:]]*as[[:space:]]*.*$$//g' \
		| xargs -n1 docker pull;

login:
	yes | docker login --username $(USER) --password $(PASS)

push:
	@$(MAKE) tag TAG=$(TAG)
	docker push $(IMAGE):$(TAG)

enter:
	docker run --rm --name $(subst /,-,$(IMAGE)) -it --entrypoint=/bin/sh $(ARG) $(IMAGE):$(TAG)
