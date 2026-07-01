SHELL := /bin/bash
SCRIPTS := scripts
UNAME_S := $(shell uname -s)

.DEFAULT_GOAL := help

.PHONY: help open-github run

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

run: ## run the bootstrap
	@bash zeroBringup.sh

open-github: ## Open the GitHub repository in the default browser (macOS/Linux)
	@remote=$$(git remote | head -1); \
	[ -n "$$remote" ] || { echo "No git remote configured."; exit 1; }; \
	url=$$(git remote get-url "$$remote" | sed -e 's|git@github.com:|https://github.com/|' -e 's|\.git$$||'); \
	echo "Opening $$url"; \
	if [ "$(UNAME_S)" = "Darwin" ]; then open "$$url"; \
	elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$$url"; \
	else echo "No browser opener found; visit: $$url"; fi
