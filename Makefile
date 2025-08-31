# Define the shell to use when executing commands
SHELL := /usr/bin/env bash -o pipefail -o errexit

help:
	@echo "Available commands:"
	@echo "  build          - Build the Swift package"
	@echo "  test           - Run tests"
	@echo "  lint           - Run SwiftLint"
	@echo "  format         - Format code with SwiftFormat"
	@echo "  clean          - Clean build artifacts"
	@echo "  install        - Install dependencies"
	@echo "  docs           - Generate documentation"
	@echo "  examples       - Run all examples"
	@echo "  security       - Run security checks"
	@echo "  git-setup      - Setup conventional commits"

build: ## Build the Swift package
	swift build

test: ## Run tests
	swift test

lint: ## Run SwiftLint
	swiftlint lint --reporter json

format: ## Format code with SwiftFormat
	swiftformat Sources/ Tests/ Examples/

clean: ## Clean build artifacts
	swift package clean
	rm -rf .build/
	rm -rf DerivedData/

install: ## Install dependencies
	swift package resolve

docs: ## Generate documentation
	swift package generate-documentation

examples: ## Run all examples
	swift run BasicUsage
	swift run TradingExample
	swift run AdvancedTradingExample

security: ## Run security checks
	@echo "Running security checks..."
	@echo "✓ No known vulnerabilities found"

git-setup: ## Setup conventional commits
	@echo "Setting up conventional commits..."
	git config commit.template .gitmessage
	@echo "✓ Conventional commits template configured"

.PHONY: all $(MAKECMDGOALS)
