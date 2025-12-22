;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;;; NEUROSYM.scm — qed-ssg neurosymbolic reasoning and verification

(define-module (qed-ssg neurosym)
  #:export (type-system verification-rules invariants formal-specs))

;;; ============================================================================
;;; TYPE SYSTEM - Semantic types for SSG domain
;;; ============================================================================

(define type-system
  '((base-types
     (AdapterName . "String matching /^[a-z][a-z0-9-]*$/")
     (Language . "Enum of supported programming languages")
     (FilePath . "Valid filesystem path")
     (Port . "Integer in range 1024-65535")
     (URL . "Valid URL string"))

    (composite-types
     (Adapter
      (fields . ((name . AdapterName)
                 (language . Language)
                 (description . String)
                 (connected . Boolean)
                 (tools . (List Tool)))))

     (Tool
      (fields . ((name . String)
                 (description . String)
                 (inputSchema . JSONSchema)
                 (execute . Function))))

     (BuildResult
      (fields . ((success . Boolean)
                 (stdout . String)
                 (stderr . String)
                 (code . Integer)))))

    (effect-types
     (IO . "Side-effecting computation")
     (Async . "Asynchronous operation")
     (Command . "Shell command execution"))))

;;; ============================================================================
;;; VERIFICATION RULES - Constraints that must hold
;;; ============================================================================

(define verification-rules
  '((adapter-invariants
     (rule-1
      (name . "unique-adapter-names")
      (predicate . "forall a1 a2 : Adapter. a1 != a2 => a1.name != a2.name")
      (description . "All adapter names must be unique"))

     (rule-2
      (name . "tool-name-prefix")
      (predicate . "forall t : Tool, a : Adapter. t in a.tools => startsWith(t.name, a.name)")
      (description . "Tool names must be prefixed with adapter name"))

     (rule-3
      (name . "connect-before-use")
      (predicate . "forall a : Adapter, t : Tool. execute(t) => a.connected")
      (description . "Adapter must be connected before tool execution")))

    (security-invariants
     (rule-1
      (name . "no-shell-injection")
      (predicate . "forall cmd : Command. isParameterized(cmd)")
      (description . "All commands must use parameterized arguments"))

     (rule-2
      (name . "no-secrets-in-code")
      (predicate . "forall f : File. not(containsSecret(f))")
      (description . "No hardcoded secrets in source files"))

     (rule-3
      (name . "spdx-headers")
      (predicate . "forall f : SourceFile. hasSPDXHeader(f)")
      (description . "All source files must have SPDX license headers")))

    (build-invariants
     (rule-1
      (name . "reproducible-builds")
      (predicate . "forall b1 b2 : Build. sameInput(b1, b2) => sameOutput(b1, b2)")
      (description . "Builds with same input produce same output"))

     (rule-2
      (name . "pinned-dependencies")
      (predicate . "forall d : Dependency. hasExactVersion(d)")
      (description . "All dependencies must be version-pinned")))))

;;; ============================================================================
;;; INVARIANTS - System-wide constraints
;;; ============================================================================

(define invariants
  '((structural
     (adapter-count . 28)
     (tools-per-adapter . ">= 4")
     (test-coverage . ">= 70%"))

    (temporal
     (build-timeout . "5 minutes")
     (test-timeout . "10 minutes")
     (adapter-connect-timeout . "30 seconds"))

    (resource
     (max-memory . "512MB")
     (max-cpu . "2 cores")
     (max-disk . "1GB"))))

;;; ============================================================================
;;; FORMAL SPECS - Algebraic specifications
;;; ============================================================================

(define formal-specs
  '((adapter-algebra
     (sort . "Adapter")
     (operations
      (connect . "Adapter -> Async<Boolean>")
      (disconnect . "Adapter -> Async<Unit>")
      (isConnected . "Adapter -> Boolean")
      (execute . "Adapter -> Tool -> Input -> Async<BuildResult>"))
     (axioms
      (idempotent-connect . "connect(connect(a)) = connect(a)")
      (disconnect-clears . "isConnected(disconnect(a)) = false")
      (connect-enables . "success(connect(a)) => isConnected(a)")))

    (build-algebra
     (sort . "Build")
     (operations
      (init . "Path -> Async<BuildResult>")
      (build . "Path -> Options -> Async<BuildResult>")
      (serve . "Path -> Port -> Async<Server>")
      (clean . "Path -> Async<BuildResult>"))
     (axioms
      (clean-idempotent . "clean(clean(p)) = clean(p)")
      (build-after-init . "success(init(p)) => canBuild(p)")
      (serve-requires-build . "success(build(p)) => canServe(p)")))))
