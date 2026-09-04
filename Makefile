# iOS Ready — command contract (master plan Section 21).
# Every target is a thin wrapper over scripts/, so CI, agents and humans all
# run exactly the same thing.

SHELL := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help bootstrap verify test-core test-runner build-ios test-ios lint \
        validate-content state-check secret-scan clean

help: ## Show available targets
	@echo "iOS Ready — make targets"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[1m%-18s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Start with: make bootstrap && make verify"

bootstrap: ## Detect the toolchain and write state/ENVIRONMENT.md
	@bash scripts/bootstrap.sh

verify: ## Run everything possible here; the one command that decides pass/fail
	@bash scripts/verify.sh

test-core: ## Run the platform-agnostic domain package tests
	@bash scripts/test-core.sh

test-runner: ## Run the Mac challenge-runner tests
	@bash scripts/test-runner.sh

build-ios: ## Build the iPhone app (Tier A only)
	@bash scripts/build-ios.sh

test-ios: ## Run iPhone app tests on a simulator (Tier A only)
	@bash scripts/test-ios.sh

validate-content: ## Validate Content/ against schemas and cross-file rules
	@bash scripts/validate-content.sh

state-check: ## Assert state/ parses and matches the repository
	@bash scripts/state-check.sh

secret-scan: ## Refuse to let a credential reach the repository
	@bash scripts/secret-scan.sh

lint: ## Formatting/lint if configured; no-op otherwise
	@if command -v swiftformat >/dev/null 2>&1 && [ -d Packages ]; then \
	  swiftformat --lint Packages App Runner 2>/dev/null || true; \
	else echo "  skip lint: no formatter configured (see master plan M0-R05)"; fi

clean: ## Remove build and verification output
	@rm -rf verify-output Packages/*/.build Runner/.build
	@echo "  cleaned"
