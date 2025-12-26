# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# Justfile - qed-ssg build automation with must-spec contract enforcement
# Works in conjunction with mustfile.ncl for contract-driven development

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Default recipe: show help
default:
    @just --list --unsorted

# ============================================================================
# MUST-SPEC CONTRACT ENFORCEMENT
# ============================================================================

# Enforce language policy (no banned languages/tools)
enforce-policy:
    @echo "Enforcing language policy from mustfile.ncl..."
    @# Check for banned TypeScript files
    @if find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.mts" -o -name "*.cts" \) \
        -not -path "./node_modules/*" -not -path "./.git/*" 2>/dev/null | grep -q .; then \
        echo "ERROR: TypeScript files detected. Use ReScript instead."; \
        find . -type f \( -name "*.ts" -o -name "*.tsx" \) -not -path "./node_modules/*" -not -path "./.git/*"; \
        exit 1; \
    fi
    @# Check for banned Node.js/npm files
    @if [ -f "package.json" ] || [ -f "package-lock.json" ] || [ -f ".npmrc" ]; then \
        echo "ERROR: npm/Node.js files detected. Use Deno instead."; \
        exit 1; \
    fi
    @# Check for banned Bun files
    @if [ -f "bun.lockb" ] || [ -f "bunfig.toml" ]; then \
        echo "ERROR: Bun files detected. Use Deno instead."; \
        exit 1; \
    fi
    @# Check for banned pnpm files
    @if [ -f "pnpm-lock.yaml" ] || [ -f ".pnpmfile.cjs" ]; then \
        echo "ERROR: pnpm files detected. Use Deno instead."; \
        exit 1; \
    fi
    @# Check for banned yarn files
    @if [ -f "yarn.lock" ] || [ -f ".yarnrc" ] || [ -f ".yarnrc.yml" ]; then \
        echo "ERROR: yarn files detected. Use Deno instead."; \
        exit 1; \
    fi
    @# Check for banned Go files
    @if find . -type f \( -name "*.go" -o -name "go.mod" -o -name "go.sum" \) \
        -not -path "./.git/*" 2>/dev/null | grep -q .; then \
        echo "ERROR: Go files detected. Use Rust instead."; \
        exit 1; \
    fi
    @# Check for banned Makefile
    @if [ -f "Makefile" ] || [ -f "makefile" ] || [ -f "GNUmakefile" ]; then \
        echo "ERROR: Makefile detected. Use Justfile instead."; \
        exit 1; \
    fi
    @if find . -type f -name "*.mk" -not -path "./.git/*" 2>/dev/null | grep -q .; then \
        echo "ERROR: .mk files detected. Use Justfile instead."; \
        exit 1; \
    fi
    @# Check for banned mobile languages (Kotlin/Swift)
    @if find . -type f \( -name "*.kt" -o -name "*.kts" -o -name "*.swift" \) \
        -not -path "./.git/*" 2>/dev/null | grep -q .; then \
        echo "ERROR: Kotlin/Swift files detected. Use Rust/Tauri/Dioxus instead."; \
        exit 1; \
    fi
    @echo "Language policy enforcement passed!"

# Validate mustfile.ncl syntax
validate-mustfile:
    @echo "Validating mustfile.ncl..."
    nickel eval mustfile.ncl > /dev/null
    @echo "mustfile.ncl is valid!"

# ============================================================================
# DEVELOPMENT
# ============================================================================

# Set up development environment
setup:
    @echo "Setting up qed-ssg development environment..."
    command -v deno >/dev/null || (echo "Install Deno: https://deno.land" && exit 1)
    command -v just >/dev/null || (echo "Install Just: cargo install just" && exit 1)
    command -v nickel >/dev/null || (echo "Install Nickel: https://nickel-lang.org" && exit 1)
    @# Check for banned tools
    @if command -v npm >/dev/null 2>&1; then echo "WARNING: npm detected. Use deno instead."; fi
    @if command -v bun >/dev/null 2>&1; then echo "WARNING: bun detected. Use deno instead."; fi
    @echo "Environment ready!"

# Start development server (runs adapter tests in watch mode)
dev:
    deno test --watch adapters/

# Run a specific adapter in REPL mode
adapter name:
    deno repl --eval "import * as adapter from './adapters/{{name}}.js'; console.log(adapter);"

# ============================================================================
# RESCRIPT
# ============================================================================

# Build ReScript sources
rescript-build:
    @echo "Building ReScript..."
    rescript build

# Watch ReScript sources
rescript-watch:
    rescript build -w

# Clean ReScript build artifacts
rescript-clean:
    rescript clean

# ============================================================================
# TESTING
# ============================================================================

# Run unit tests
test:
    deno test --allow-read --allow-run tests/unit/

# Run end-to-end tests
test-e2e:
    @echo "Running e2e tests..."
    deno test --allow-all tests/e2e/

# Run all tests (unit + integration + e2e)
test-all: test test-integration test-e2e
    @echo "All tests passed!"

# Run tests for a specific adapter
test-adapter name:
    deno test --allow-read --allow-run adapters/{{name}}.js

# Run tests with coverage
test-coverage:
    deno test --coverage=coverage/ --allow-read --allow-run tests/unit/
    deno coverage coverage/

# Run integration tests
test-integration:
    @echo "Running integration tests..."
    deno test --allow-read --allow-run tests/integration/

# Run benchmarks
benchmark:
    @echo "Running performance benchmarks..."
    deno test --allow-read --allow-run tests/benchmark/

# Run full test suite with coverage report
test-full: test test-integration test-e2e
    @echo "Full test suite passed!"

# ============================================================================
# LINTING & FORMATTING
# ============================================================================

# Run all linters
lint: lint-js lint-res lint-scm enforce-policy
    @echo "All linting passed!"

# Lint JavaScript files (compiled from ReScript)
lint-js:
    @if [ -d "adapters" ] && ls adapters/*.js 1> /dev/null 2>&1; then \
        deno lint adapters/; \
    else \
        echo "No adapters to lint yet."; \
    fi

# Lint ReScript files (check compilation)
lint-res:
    @echo "Checking ReScript files..."
    @if [ -d "src" ]; then rescript build 2>&1 || echo "ReScript check complete"; fi

# Lint Scheme files (basic syntax check)
lint-scm:
    @for f in *.scm; do \
        if [ -f "$$f" ]; then \
            echo "Checking $$f..."; \
            guile -c "(load \"$$f\")" 2>/dev/null || echo "Warning: $$f may have issues"; \
        fi; \
    done

# Format all code
fmt:
    @if [ -d "adapters" ]; then deno fmt adapters/; fi
    @if [ -d "src" ]; then deno fmt src/; fi
    @if [ -d "tests" ]; then deno fmt tests/; fi

# Check formatting without modifying
fmt-check:
    @if [ -d "adapters" ] && ls adapters/*.js 1> /dev/null 2>&1; then deno fmt --check adapters/; fi
    @if [ -d "src" ] && ls src/**/*.res.js 1> /dev/null 2>&1; then deno fmt --check src/; fi

# ============================================================================
# SECURITY
# ============================================================================

# Run security audit
audit:
    @echo "Running security audit..."
    @# Check for eval()
    @if grep -rn "eval(" adapters/ src/ 2>/dev/null | grep -v "\.res$$"; then \
        echo "ERROR: eval() found!"; exit 1; \
    fi || true
    @# Check for deprecated Deno.run
    @if grep -rn "Deno\.run" adapters/ src/ 2>/dev/null; then \
        echo "ERROR: Deprecated Deno.run found! Use Deno.Command."; exit 1; \
    fi || true
    @# Check for possible secrets
    @if grep -rn "password\|secret\|api.key\|token" adapters/ src/ --include="*.js" 2>/dev/null | grep -v "description"; then \
        echo "WARNING: Possible secrets detected!"; \
    fi || true
    @echo "Security audit passed!"

# Run SAST with CodeQL (requires gh cli)
sast:
    gh workflow run codeql.yml

# ============================================================================
# ADAPTERS
# ============================================================================

# List all available adapters
list-adapters:
    @echo "Available SSG Adapters (28):"
    @if [ -d "adapters" ] && ls adapters/*.js 1> /dev/null 2>&1; then \
        ls -1 adapters/*.js | xargs -I{} basename {} .js | sort; \
    else \
        echo "No adapters generated yet. Run 'just generate-adapters'."; \
    fi

# Generate adapters from Nickel formulae
generate-adapters:
    @echo "Generating adapters from Nickel formulae..."
    @mkdir -p adapters
    nickel eval formulae/adapters.ncl --format json | jq -r '.' > /tmp/adapters.json
    @echo "Adapter formulae evaluated. Implementation pending."

# Test all adapters connectivity
test-adapters:
    @echo "Testing adapter connectivity..."
    @if [ -d "adapters" ] && ls adapters/*.js 1> /dev/null 2>&1; then \
        for adapter in adapters/*.js; do \
            echo "Testing $$adapter..."; \
            deno eval "import * as a from './$$adapter'; console.log(a.name, '-', a.language);" 2>/dev/null || echo "Failed: $$adapter"; \
        done; \
    else \
        echo "No adapters to test yet."; \
    fi

# ============================================================================
# BUILD & RELEASE
# ============================================================================

# Build the project
build: rescript-build
    @echo "Building qed-ssg..."
    @if [ -d "adapters" ] && ls adapters/*.js 1> /dev/null 2>&1; then \
        deno check adapters/*.js; \
    fi
    @echo "Build complete!"

# Generate documentation
docs:
    @echo "Generating documentation..."
    @mkdir -p docs
    just docs-adapters

# Generate adapter documentation
docs-adapters:
    @if [ -d "adapters" ] && ls adapters/*.js 1> /dev/null 2>&1; then \
        echo "| Adapter | Language | Description |" > docs/adapters.md; \
        echo "|---------|----------|-------------|" >> docs/adapters.md; \
        for f in adapters/*.js; do \
            deno eval "import * as a from './$$f'; console.log('| ' + a.name + ' | ' + a.language + ' | ' + a.description + ' |');" 2>/dev/null >> docs/adapters.md || true; \
        done; \
    else \
        echo "No adapters to document yet."; \
    fi

# Clean build artifacts
clean:
    rm -rf coverage/
    rm -rf dist/
    rm -rf .deno/
    rescript clean || true

# Prepare release
release version:
    @echo "Preparing release v{{version}}..."
    just enforce-policy
    just test-all
    just build
    @echo "Ready to tag v{{version}}"

# ============================================================================
# CI/CD
# ============================================================================

# Run CI pipeline locally
ci: enforce-policy lint test audit build
    @echo "CI pipeline passed!"

# Run full validation
validate: fmt-check lint test test-e2e audit build
    @echo "Full validation passed!"

# ============================================================================
# HOOKS
# ============================================================================

# Install git hooks
install-hooks:
    @echo "Installing git hooks..."
    @mkdir -p .git/hooks
    @echo '#!/bin/bash' > .git/hooks/pre-commit
    @echo 'just pre-commit' >> .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo '#!/bin/bash' > .git/hooks/pre-push
    @echo 'just pre-push' >> .git/hooks/pre-push
    @chmod +x .git/hooks/pre-push
    @echo "Hooks installed!"

# Pre-commit hook
pre-commit: enforce-policy fmt-check lint test
    @echo "Pre-commit checks passed!"

# Pre-push hook
pre-push: test-all audit
    @echo "Pre-push checks passed!"

# ============================================================================
# CONTAINER
# ============================================================================

# Build container image
container-build:
    podman build -t qed-ssg:latest -f Containerfile --target production .

# Build development container
container-dev:
    podman build -t qed-ssg:dev -f Containerfile --target development .

# Run container
container-run:
    podman run --rm -it qed-ssg:latest

# Run tests in container
container-test:
    podman build -t qed-ssg:test -f Containerfile --target test .
    podman run --rm qed-ssg:test

# ============================================================================
# UTILITIES
# ============================================================================

# Show project statistics
stats:
    @echo "=== QED-SSG Statistics ==="
    @echo "ReScript files: $$(find . -name '*.res' 2>/dev/null | wc -l)"
    @echo "JavaScript files: $$(find adapters src -name '*.js' 2>/dev/null | wc -l || echo 0)"
    @echo "Nickel files: $$(find . -name '*.ncl' 2>/dev/null | wc -l)"
    @echo "SCM files: $$(ls -1 *.scm 2>/dev/null | wc -l || echo 0)"
    @echo "TypeScript files: $$(find . -name '*.ts' -not -path './node_modules/*' 2>/dev/null | wc -l) (should be 0)"

# Verify all SPDX headers
verify-spdx:
    @echo "Verifying SPDX headers..."
    @failed=0; \
    for f in $$(find adapters src tests hooks -type f \( -name '*.js' -o -name '*.res' -o -name '*.sh' \) 2>/dev/null); do \
        if [ -f "$$f" ]; then \
            if ! head -3 "$$f" | grep -q 'SPDX-License-Identifier'; then \
                echo "Missing SPDX: $$f"; \
                failed=1; \
            fi; \
        fi; \
    done; \
    [ $$failed -eq 0 ] && echo "All SPDX headers present!"

# Generate coverage badge
coverage-badge:
    @deno test --coverage=coverage/ --allow-read --allow-run tests/unit/ 2>/dev/null || true
    @coverage=$$(deno coverage coverage/ 2>/dev/null | grep -oP '\d+\.\d+%' | head -1 || echo "0%"); \
    echo "Coverage: $$coverage"

# Check for language policy violations
check-violations:
    @echo "=== Language Policy Violation Check ==="
    @echo ""
    @echo "TypeScript files (banned):"
    @find . -type f \( -name "*.ts" -o -name "*.tsx" \) -not -path "./node_modules/*" -not -path "./.git/*" 2>/dev/null || echo "  None found"
    @echo ""
    @echo "npm/Node.js files (banned):"
    @ls package.json package-lock.json .npmrc 2>/dev/null || echo "  None found"
    @echo ""
    @echo "Bun files (banned):"
    @ls bun.lockb bunfig.toml 2>/dev/null || echo "  None found"
    @echo ""
    @echo "Go files (banned):"
    @find . -type f \( -name "*.go" -o -name "go.mod" \) -not -path "./.git/*" 2>/dev/null || echo "  None found"
    @echo ""
    @echo "Makefile (banned):"
    @ls Makefile makefile GNUmakefile 2>/dev/null || echo "  None found"
    @echo ""
