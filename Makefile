-include Makefile.local # for optional local options

BUILD_TARGET ::= bin/catalog_tools

# The shards command to use
SHARDS ?= shards
# The crystal command to use
CRYSTAL ?= crystal

SRC_SOURCES ::= $(shell find src -name '*.cr' 2>/dev/null)
LIB_SOURCES ::= $(shell find lib -name '*.cr' 2>/dev/null)
SPEC_SOURCES ::= $(shell find spec -name '*.cr' 2>/dev/null)

.PHONY: build
build: ## Build the application binary
build: $(BUILD_TARGET)

$(BUILD_TARGET): $(SRC_SOURCES) $(LIB_SOURCES) lib
	mkdir -p $(shell dirname $(@))
	$(CRYSTAL) build src/cli.cr -o $(@)

.PHONY: test
test: ## Run the test suite
test: format
	# Ensure there are no changes after running the formatter
	git diff --exit-code catalog

	# format Crystal code as well
	crystal tool format --check src spec

.PHONY: format
format: ## Apply catalog formatting
format: $(BUILD_TARGET)
	$(BUILD_TARGET) format

.PHONY: src/format
src/format: ## Apply source code formatting
src/format: $(SRC_SOURCES) $(SPEC_SOURCES)
	$(CRYSTAL) tool format src spec

docs: ## Generate API docs
docs: $(SRC_SOURCES) lib
	$(CRYSTAL) docs -o docs

lib: shard.lock
	$(SHARDS) install
	# Touch is necessary because `shards install` always touches shard.lock
	touch lib

shard.lock: shard.yml
	$(SHARDS) update

.PHONY: clean
clean: ## Remove application binary
clean:
	@rm -f $(BUILD_TARGET)

.PHONY: help
help: ## Show this help
	@echo
	@printf '\033[34mtargets:\033[0m\n'
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) |\
		sort |\
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo
	@printf '\033[34moptional variables:\033[0m\n'
	@grep -hE '^[a-zA-Z_-]+ \?=.*?## .*$$' $(MAKEFILE_LIST) |\
		sort |\
		awk 'BEGIN {FS = " \\?=.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo
	@printf '\033[34mrecipes:\033[0m\n'
	@grep -hE '^##.*$$' $(MAKEFILE_LIST) |\
		awk 'BEGIN {FS = "## "}; /^## [a-zA-Z_-]/ {printf "  \033[36m%s\033[0m\n", $$2}; /^##  / {printf "  %s\n", $$2}'
