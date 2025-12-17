;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;;; META.scm — qed-ssg

(define-module (qed-ssg meta)
  #:export (architecture-decisions development-practices design-rationale))

(define architecture-decisions
  '((adr-001
     (title . "RSR Compliance")
     (status . "accepted")
     (date . "2025-12-15")
     (context . "qed-ssg is a satellite SSG project in the hyperpolymath ecosystem")
     (decision . "Follow Rhodium Standard Repository guidelines")
     (consequences . ("RSR Gold target" "SHA-pinned actions" "SPDX headers" "Multi-platform CI")))
    (adr-002
     (title . "MCP Adapter Architecture")
     (status . "accepted")
     (date . "2025-12-17")
     (context . "Need to integrate with poly-ssg-mcp hub for 28 SSG adapters")
     (decision . "Use Deno-based JavaScript adapters with MCP protocol")
     (consequences . ("Deno runtime required" "Secure command execution" "Consistent adapter interface")))))

(define development-practices
  '((code-style (languages . ("javascript" "scheme")) (formatter . "prettier") (linter . "eslint"))
    (security (sast . "CodeQL") (credentials . "env vars only") (command-execution . "parameterized args only"))
    (testing (coverage-minimum . 70))
    (versioning (scheme . "SemVer 2.0.0"))))

(define design-rationale
  '((why-rsr "RSR ensures consistency, security, and maintainability.")))
