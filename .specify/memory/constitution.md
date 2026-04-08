<!--
Sync Impact Report
- Version change: template-placeholder -> 1.0.0
- Modified principles:
	- Template Principle 1 -> I. Plain-Stack Implementation
	- Template Principle 2 -> II. Config-Driven Sources of Truth
	- Template Principle 3 -> III. Failure-Aware Routing and Resilience
	- Template Principle 4 -> IV. Layered and Versioned Composition
	- Template Principle 5 -> V. Demo-First Verifiability
	- Added: VI. Secure-by-Default Operations
	- Added: VII. Deterministic and Reproducible Behavior
- Added sections:
	- Implementation Constraints
	- Workflow and Quality Gates
- Removed sections:
	- None
- Templates requiring updates:
	- ✅ .specify/templates/plan-template.md
	- ✅ .specify/templates/spec-template.md
	- ✅ .specify/templates/tasks-template.md
	- ⚠ pending .specify/templates/commands/*.md (directory not present)
- Follow-up TODOs:
	- None
-->

# From Specs to Mission-Critical Deployments Constitution

## Core Principles

### I. Plain-Stack Implementation
All deliverables MUST use plain HTML/CSS/JavaScript, standard Bicep, and vanilla
Python only. Frameworks, bundlers, and architecture migrations MUST NOT be added
without an explicit constitution amendment. This keeps the demo portable, auditable,
and easy to reproduce in constrained environments.

### II. Config-Driven Sources of Truth
Behavioral and visual tuning MUST be declared in configuration structures rather
than scattered literals. `SVG_CONFIG` and `STATE` govern the demo app,
`aiServicesConfig` and module parameters govern backend routing, and `params.json`
governs deployment inputs. This enables reviewable change sets and predictable
runtime behavior.

### III. Failure-Aware Routing and Resilience
Routing and retry logic MUST be failure-aware by design. The system MUST treat
`429` and `503` as retry/failover signals, enforce circuit-breaker semantics in
gateway policy, and route in a deterministic round-robin pattern across healthy
backends only. This is non-negotiable for mission-critical credibility.

### IV. Layered and Versioned Composition
The repository MUST preserve three aligned layers: HTML app, Bicep infra, and
Jupyter runbook. Bicep modules MUST remain versioned (`vN`) and composable, and
shared Python utilities MUST stay reusable under `shared/`. Cross-layer changes
MUST describe interface impact explicitly.

### V. Demo-First Verifiability
The runbook MUST keep explicit step numbering (Step 0 through Step 10d), and
changes MUST preserve visual and trace-based proof of routing behavior. APIM trace
attribution is the authoritative routing record for claims about backend
distribution.

### VI. Secure-by-Default Operations
All backend integrations MUST use HTTPS endpoints, APIM managed identity, and RBAC
least privilege. Secrets and credentials MUST NOT be hardcoded in Bicep, notebooks,
or utility scripts. Credential flow MUST derive from Azure CLI context or secure
platform identity.

### VII. Deterministic and Reproducible Behavior
Naming, routing, and execution flow MUST be reproducible. Resource naming MUST use
deterministic `uniqueString()` suffixes, routing logic MUST be deterministic under
identical health conditions, and notebook steps MUST execute in documented
sequential order without hidden prerequisites.

## Implementation Constraints

- HTML App (`index.html`): Keep `SVG_CONFIG` and mutable runtime state near the top,
	preserve deterministic packet flow, and preserve SVG layer ordering so packets and
	labels render above base elements.
- Bicep Infra (`main.bicep`, `modules/`, `policy.xml`): Keep policy XML external,
	include `@description` decorators for parameters, and preserve module versioning
	directories when evolving functionality.
- Runbook (`runbook.ipynb`, `shared/utils.py`): Preserve numbered instructional
	sequence and keep reusable CLI/output helpers in shared utilities instead of
	duplicating code in notebook cells.

## Workflow and Quality Gates

- Every spec and plan MUST include a constitution check that maps intended changes
	to all impacted layers.
- Every task list MUST include explicit compliance tasks for determinism, security,
	and failure-aware behavior when those concerns are in scope.
- Before merge, contributors MUST provide evidence appropriate to the changed layer:
	browser behavior validation for `index.html`, Bicep/policy validation for infra,
	and runbook trace-backed verification for routing claims.
- Pull requests SHOULD remain focused and avoid unrelated architecture changes.

## Governance

This constitution supersedes local conventions for this repository. Amendments MUST
be proposed in writing, include rationale and migration impact, and be accepted by
project maintainers before implementation. Compliance reviews are required for
specifications, plans, tasks, and pull requests that touch governed artifacts.

Versioning policy follows semantic versioning for governance:
- MAJOR: backward-incompatible principle removals or redefinitions.
- MINOR: new principle or materially expanded mandatory guidance.
- PATCH: clarifications, wording improvements, and non-semantic edits.

Reviewers MUST reject changes that violate mandatory principles unless the same
change set includes an approved constitution amendment.

**Version**: 1.0.0 | **Ratified**: 2026-04-08 | **Last Amended**: 2026-04-08
