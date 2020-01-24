BIN ?= bin
SHARDS := shards

.PHONY: test
test: format
	# Ensure there are no changes after running the formatter
	git diff --exit-code catalog

	# format Crystal code as well
	crystal tool format --check src spec

.PHONY: build
build: $(BIN)/catalog_tools

$(BIN)/catalog_tools: src/* shard.lock
	$(SHARDS) build catalog_tools

shard.lock: shard.yml
	$(SHARDS) update

.PHONY: format
format: $(BIN)/catalog_tools
	$(BIN)/catalog_tools format

.PHONY: clean
clean:
	rm -f $(BIN)/catalog_tools
