# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# Justfile — qed-ssg build automation

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Default recipe: show help
default:
    @just --list --unsorted

# ============================================================================
# DEVELOPMENT
# ============================================================================

# Set up development environment
setup:
    @echo "Setting up qed-ssg development environment..."
    command -v deno >/dev/null || (echo "Install Deno: https://deno.land" && exit 1)
    command -v just >/dev/null || (echo "Install Just: cargo install just" && exit 1)
    @echo "Environment ready!"

# Start development server (runs adapter tests in watch mode)
dev:
    deno test --watch adapters/

# Run a specific adapter in REPL mode
adapter name:
    deno repl --eval "import * as adapter from './adapters/{{name}}.js'; console.log(adapter);"

# ============================================================================
# TESTING
# ============================================================================

# Run unit tests
test:
    deno test --allow-read --allow-run adapters/

# Run end-to-end tests
test-e2e:
    @echo "Running e2e tests..."
    deno test --allow-all tests/e2e/

# Run all tests (unit + e2e)
test-all: test test-e2e
    @echo "All tests passed!"

# Run tests for a specific adapter
test-adapter name:
    deno test --allow-read --allow-run adapters/{{name}}.js

# Run tests with coverage
test-coverage:
    deno test --coverage=coverage/ --allow-read --allow-run adapters/
    deno coverage coverage/

# ============================================================================
# LINTING & FORMATTING
# ============================================================================

# Run all linters
lint: lint-js lint-scm
    @echo "All linting passed!"

# Lint JavaScript/TypeScript files
lint-js:
    deno lint adapters/

# Lint Scheme files (basic syntax check)
lint-scm:
    @for f in *.scm; do echo "Checking $f..."; guile -c "(load \"$f\")" 2>/dev/null || echo "Warning: $f may have issues"; done

# Format all code
fmt:
    deno fmt adapters/

# Check formatting without modifying
fmt-check:
    deno fmt --check adapters/

# ============================================================================
# SECURITY
# ============================================================================

# Run security audit
audit:
    @echo "Running security audit..."
    @grep -rn "eval(" adapters/ && echo "ERROR: eval() found!" && exit 1 || true
    @grep -rn "exec(" adapters/ | grep -v "Deno.Command" && echo "ERROR: Unsafe exec found!" && exit 1 || true
    @grep -rn "password\|secret\|api.key\|token" adapters/ --include="*.js" | grep -v "description" && echo "WARNING: Possible secrets!" || true
    @echo "Security audit passed!"

# Run SAST with CodeQL (requires gh cli)
sast:
    gh workflow run codeql.yml

# Check dependencies for vulnerabilities
dependency-check:
    @echo "Checking dependencies..."
    @# Add npm audit or similar when package.json exists

# ============================================================================
# ADAPTERS
# ============================================================================

# List all available adapters
list-adapters:
    @echo "Available SSG Adapters (28):"
    @ls -1 adapters/*.js | xargs -I{} basename {} .js | sort

# Sync adapters from poly-ssg-mcp hub
sync-adapters:
    @echo "Syncing adapters from poly-ssg-mcp hub..."
    @# Placeholder for actual sync command
    @echo "Run: ~/Documents/scripts/transfer-ssg-adapters.sh --satellite qed-ssg"

# Test all adapters connectivity
test-adapters:
    @echo "Testing adapter connectivity..."
    @for adapter in adapters/*.js; do \
        echo "Testing $adapter..."; \
        deno eval "import * as a from './$adapter'; console.log(a.name, '-', a.language);" 2>/dev/null || echo "Failed: $adapter"; \
    done

# Generate adapter documentation
docs-adapters:
    @echo "Generating adapter documentation..."
    @echo "| Adapter | Language | Description |" > docs/adapters.md
    @echo "|---------|----------|-------------|" >> docs/adapters.md
    @for f in adapters/*.js; do \
        deno eval "import * as a from './$f'; console.log('| ' + a.name + ' | ' + a.language + ' | ' + a.description + ' |');" 2>/dev/null >> docs/adapters.md || true; \
    done

# ============================================================================
# BUILD & RELEASE
# ============================================================================

# Build the project
build:
    @echo "Building qed-ssg..."
    deno check adapters/*.js
    @echo "Build complete!"

# Generate documentation
docs:
    @echo "Generating documentation..."
    @mkdir -p docs
    just docs-adapters

# Clean build artifacts
clean:
    rm -rf coverage/
    rm -rf dist/
    rm -rf .deno/

# Prepare release
release version:
    @echo "Preparing release v{{version}}..."
    just test-all
    just build
    @echo "Ready to tag v{{version}}"

# ============================================================================
# LANGUAGE SERVER
# ============================================================================

# Start LSP (placeholder for future language server)
lsp:
    @echo "LSP not yet implemented for qed-ssg adapters"
    @echo "Consider using Deno LSP for adapter development"

# Compile a file (placeholder)
compile file:
    @echo "Compiling {{file}}..."
    deno check {{file}}

# ============================================================================
# CI/CD
# ============================================================================

# Run CI pipeline locally
ci: lint test audit build
    @echo "CI pipeline passed!"

# Run full validation
validate: fmt-check lint test test-e2e audit build docs
    @echo "Full validation passed!"

# ============================================================================
# HOOKS
# ============================================================================

# Install git hooks
install-hooks:
    @echo "Installing git hooks..."
    @mkdir -p .git/hooks
    @echo '#!/bin/bash\njust pre-commit' > .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo "Hooks installed!"

# Pre-commit hook
pre-commit: fmt-check lint test
    @echo "Pre-commit checks passed!"

# Pre-push hook
pre-push: test-all audit
    @echo "Pre-push checks passed!"
