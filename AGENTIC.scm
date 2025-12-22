;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;;; AGENTIC.scm — qed-ssg agent capabilities and tool definitions

(define-module (qed-ssg agentic)
  #:export (agent-capabilities mcp-tools adapter-registry permissions))

;;; ============================================================================
;;; AGENT CAPABILITIES - What AI agents can do with this project
;;; ============================================================================

(define agent-capabilities
  '((code-generation
     (languages . ("javascript" "typescript" "scheme" "nickel"))
     (targets . ("adapters" "tests" "documentation"))
     (constraints . ("SPDX headers required" "No hardcoded secrets" "Parameterized commands only")))

    (code-review
     (focus . ("security" "performance" "correctness"))
     (rules . "copilot-instructions.md")
     (reject-patterns . ("eval()" "hardcoded secrets" "shell string concat")))

    (testing
     (generate . ("unit tests" "integration tests" "e2e tests"))
     (coverage-target . 70)
     (frameworks . ("deno test" "jest")))

    (documentation
     (formats . ("asciidoc" "markdown" "jsdoc"))
     (auto-generate . ("API docs" "adapter docs" "changelog")))

    (refactoring
     (scope . ("adapters" "build system" "tests"))
     (preserve . ("interfaces" "backwards compatibility"))
     (require-tests . #t))))

;;; ============================================================================
;;; MCP TOOLS - Model Context Protocol tool definitions
;;; ============================================================================

(define mcp-tools
  '((adapter-tools
     (description . "Tools exposed by SSG adapters via MCP protocol")
     (pattern . "{ssg}_init, {ssg}_build, {ssg}_serve, {ssg}_clean, {ssg}_version")
     (adapters . 28)
     (total-tools . 140))  ; ~5 tools per adapter

    (meta-tools
     (list-adapters
      (description . "List all available SSG adapters")
      (input . ())
      (output . "Array of adapter metadata"))

     (adapter-status
      (description . "Check adapter connection status")
      (input . ("adapter_name"))
      (output . "Connection status and version"))

     (batch-build
      (description . "Build with multiple SSGs")
      (input . ("adapters[]" "source_path" "output_path"))
      (output . "Build results per adapter")))))

;;; ============================================================================
;;; ADAPTER REGISTRY - All 28 SSG adapters
;;; ============================================================================

(define adapter-registry
  '((rust
     (adapters . ("cobalt" "mdbook" "zola"))
     (runtime . "native"))

    (haskell
     (adapters . ("hakyll" "ema"))
     (runtime . "stack"))

    (elixir
     (adapters . ("serum" "tableau" "nimble-publisher"))
     (runtime . "mix"))

    (clojure
     (adapters . ("babashka" "cryogen" "perun"))
     (runtime . "clojure/bb"))

    (julia
     (adapters . ("franklin" "documenter" "staticwebpages"))
     (runtime . "julia"))

    (scala
     (adapters . ("laika" "scalatex"))
     (runtime . "sbt"))

    (racket
     (adapters . ("frog" "pollen"))
     (runtime . "racket"))

    (other
     (adapters . (("fornax" . "f#")
                  ("orchid" . "kotlin")
                  ("marmot" . "crystal")
                  ("coleslaw" . "common-lisp")
                  ("nimrod" . "nim")
                  ("reggae" . "d")
                  ("publish" . "swift")
                  ("wub" . "tcl")
                  ("yocaml" . "ocaml")
                  ("zotonic" . "erlang"))))))

;;; ============================================================================
;;; PERMISSIONS - Agent access controls
;;; ============================================================================

(define permissions
  '((read
     (allow . ("*"))
     (description . "Read access to all files"))

    (write
     (allow . ("adapters/" "tests/" "docs/"))
     (deny . (".env" "secrets/" "*.key" "*.pem"))
     (description . "Write access with secret protection"))

    (execute
     (allow . ("just" "must" "deno" "npm" "git"))
     (deny . ("rm -rf" "sudo" "curl | sh"))
     (description . "Safe command execution"))

    (network
     (allow . ("localhost" "github.com" "deno.land"))
     (deny . ("*"))
     (description . "Restricted network access"))))
