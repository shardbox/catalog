SHARDS ::= shards

SRC_SOURCES ::= $(shell find src -name '*.cr' 2>/dev/null)
LIB_SOURCES ::= $(shell find lib -name '*.cr' 2>/dev/null)

.PHONY: test
test: format
	# Ensure there are no changes after running the formatter
	git diff --exit-code catalog

	# format Crystal code as well
	crystal tool format --check src spec

.PHONY: format
format: bin/catalog_tools
	bin/catalog_tools format

bin/catalog_tools: $(SRC_SOURCES) $(LIB_SOURCES) lib
	$(SHARDS) build catalog_tools

.PHONY: build
build: bin/catalog_tools

lib: shard.lock
	$(SHARDS) install

shard.lock: shard.yml
	$(SHARDS) update

.PHONY: clean
clean: ## Remove application binary
	rm -f bin/catalog_tools

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
