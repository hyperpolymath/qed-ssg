;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;;; PLAYBOOK.scm — qed-ssg operational playbook

(define-module (qed-ssg playbook)
  #:export (workflows commands recipes integrations))

;;; ============================================================================
;;; WORKFLOWS - Operational sequences for common tasks
;;; ============================================================================

(define workflows
  '((development
     (name . "Local Development")
     (steps . ("just setup" "just dev" "just test"))
     (description . "Set up local environment and start development server"))

    (testing
     (name . "Full Test Suite")
     (steps . ("just lint" "just test" "just test-e2e" "just audit"))
     (description . "Run all tests including unit, integration, and e2e"))

    (release
     (name . "Release Process")
     (steps . ("just test-all" "just build" "just changelog" "git tag" "just publish"))
     (description . "Prepare and publish a new release"))

    (adapter-sync
     (name . "Sync Adapters from Hub")
     (steps . ("just sync-adapters" "just test-adapters" "just docs-adapters"))
     (description . "Synchronize adapters from poly-ssg-mcp hub"))

    (security-audit
     (name . "Security Audit")
     (steps . ("just audit" "just sast" "just dependency-check"))
     (description . "Run comprehensive security audit"))))

;;; ============================================================================
;;; COMMANDS - Available CLI commands
;;; ============================================================================

(define commands
  '((build
     (justfile . "just build")
     (mustfile . "must build")
     (description . "Build the project"))

    (test
     (justfile . "just test")
     (mustfile . "must test")
     (description . "Run unit tests"))

    (test-e2e
     (justfile . "just test-e2e")
     (mustfile . "must test-e2e")
     (description . "Run end-to-end tests"))

    (test-all
     (justfile . "just test-all")
     (mustfile . "must test-all")
     (description . "Run all test suites"))

    (lint
     (justfile . "just lint")
     (mustfile . "must lint")
     (description . "Run linters on codebase"))

    (fmt
     (justfile . "just fmt")
     (mustfile . "must fmt")
     (description . "Format code"))

    (audit
     (justfile . "just audit")
     (mustfile . "must audit")
     (description . "Run security audit"))

    (dev
     (justfile . "just dev")
     (mustfile . "must dev")
     (description . "Start development server"))

    (docs
     (justfile . "just docs")
     (mustfile . "must docs")
     (description . "Generate documentation"))

    (clean
     (justfile . "just clean")
     (mustfile . "must clean")
     (description . "Clean build artifacts"))

    (sync-adapters
     (justfile . "just sync-adapters")
     (mustfile . "must sync-adapters")
     (description . "Sync adapters from poly-ssg-mcp hub"))

    (lsp
     (justfile . "just lsp")
     (mustfile . "must lsp")
     (description . "Start language server"))))

;;; ============================================================================
;;; RECIPES - Task composition patterns
;;; ============================================================================

(define recipes
  '((ci-pipeline
     (tasks . ("lint" "test" "test-e2e" "audit" "build"))
     (parallel . ("lint" "audit"))
     (sequential . ("test" "test-e2e" "build")))

    (quick-check
     (tasks . ("lint" "test"))
     (description . "Fast pre-commit check"))

    (full-validation
     (tasks . ("fmt-check" "lint" "test" "test-e2e" "audit" "docs"))
     (description . "Complete validation before release"))

    (adapter-validate
     (tasks . ("test-adapters" "lint-adapters" "docs-adapters"))
     (description . "Validate all SSG adapters"))))

;;; ============================================================================
;;; INTEGRATIONS - External service hooks
;;; ============================================================================

(define integrations
  '((github-actions
     (workflows . ("ci.yml" "codeql.yml" "release.yml"))
     (triggers . ("push" "pull_request" "schedule")))

    (dependabot
     (ecosystems . ("github-actions" "npm" "cargo" "mix" "pip" "nix"))
     (frequency . "weekly"))

    (mcp-hub
     (name . "poly-ssg-mcp")
     (sync-method . "git subtree")
     (adapters . 28))))
