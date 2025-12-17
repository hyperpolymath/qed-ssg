;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — qed-ssg

(ecosystem
  (version "1.0.0")
  (name "qed-ssg")
  (type "project")
  (purpose "Satellite SSG implementation with MCP adapters for 28 static site generators")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project
      (name "poly-ssg-mcp")
      (url "https://github.com/hyperpolymath/poly-ssg-mcp")
      (relationship "hub")
      (description "Unified MCP server for 28 SSGs - provides adapter interface")
      (differentiation
        "poly-ssg-mcp = Hub with all SSG adapters via MCP
         This project = Satellite SSG implementation using the hub"))
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "Satellite SSG implementation providing MCP adapters for 28 static site generators")
  (what-this-is-not "- NOT a standalone SSG
         - NOT exempt from RSR compliance"))
