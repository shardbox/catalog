BIN ?= bin

.PHONY: test
test: format
	crystal tool format src

.PHONY: build
build: $(BIN)/catalog_tools

$(BIN):
	mkdir -p $(BIN)

$(BIN)/catalog_tools: $(BIN) src/*
	crystal build src/cli.cr -o $(BIN)/catalog_tools

.PHONY: format
format: $(BIN)/catalog_tools
	$(BIN)/catalog_tools format

.PHONY: clean
clean:
	rm -f $(BIN)/catalog_tools
