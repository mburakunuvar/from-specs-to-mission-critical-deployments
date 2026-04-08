# Implementation Plan: Azure AI Gateway Backend Pool Demo

**Branch**: `001-ai-gateway-routing-demo` | **Date**: 2026-04-08 | **Spec**: [/specs/001-ai-gateway-routing-demo/spec.md](/specs/001-ai-gateway-routing-demo/spec.md)
**Input**: Feature specification from `/specs/001-ai-gateway-routing-demo/spec.md`
**Last Updated**: 2026-04-08 — refreshed to incorporate spec clarification session (FR-013, CA-006, FR-004 color spec, SC-001 extension, 7 assumptions)

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Deliver a three-layer, failure-aware demo that keeps routing behavior consistent
across: (1) SVG visualization in `index.html` with packet-level color coding
(blue/green for normal, orange/amber for failover, red/orange node fill for
all-unhealthy state), (2) APIM + Foundry Bicep deployment, and (3) runbook trace
validation in `runbook.ipynb`. Implementation prioritizes critical audit fixes
(HTTPS backend protocol and strict deployment-to-service mapping) before enhancement
work, while preserving plain-stack constraints and deterministic behavior.

## Technical Context

**Language/Version**: JavaScript (ES6+ vanilla), Bicep (Azure CLI 2.x), Python 3.12
**Primary Dependencies**: None for HTML layer; Azure Bicep CLI for infra; `openai`, `requests`, `pandas`, `matplotlib` for runbook
**Storage**: N/A (stateless demo; Azure resources provisioned at deploy time)
**Testing**: Manual browser validation for HTML, Azure deployment validation for Bicep, sequential runbook execution and trace checks
**Target Platform**: Browser (`index.html`), Azure cloud (Bicep deployment), VS Code Jupyter (`runbook.ipynb`)
**Project Type**: Multi-layer demo (static web page + IaC templates + lab notebook)
**Performance Goals**: Demo reliability for 5-request baseline and 20-request extended routing tests; packet animation timing deferred to implementation defaults (no explicit constraint)
**Constraints**: No frameworks, no build tools, no hardcoded secrets, HTTPS-only backends, deterministic healthy-backend routing
**Scale/Scope**: Four-backend pool, single APIM instance, single runbook flow (Step 0–Step 10d)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `Plain-Stack`: Confirms no frameworks/build tooling are introduced across HTML,
  Bicep, or runbook assets.
- `Config-Driven`: Identifies the source-of-truth config touched (`SVG_CONFIG`,
  `aiServicesConfig`, `params.json`, or equivalent) and verifies no hidden literals.
- `Failure-Aware`: Documents how 429/503 retry, circuit-breaker behavior, and
  healthy-backend routing are preserved or updated.
- `Layer Integrity`: Lists impacted layers (HTML app, infra modules/policy,
  notebook/utils) and describes boundary/interface changes.
- `Security`: Verifies managed identity + RBAC posture and confirms no hardcoded
  credentials or insecure endpoints.
- `Determinism`: Explains reproducibility impact for naming, routing, and runbook
  execution sequence.

### Pre-Phase 0 Gate Assessment

- `Plain-Stack`: PASS. No new frameworks/tooling introduced in planned work.
- `Config-Driven`: PASS. `params.json` remains the source of truth; `SVG_CONFIG`
  and runbook variables are aligned through documented contracts. Packet color scheme
  (blue/green normal, orange/amber failover, red/orange all-unhealthy) encoded in
  `SVG_CONFIG` constants — no scattered literals.
- `Failure-Aware`: PASS with planned fix. Preserve retry on 429/503 and round-robin
  healthy routing; FR-013 adds all-backends-unhealthy guard; evaluate and optionally
  extend breaker scope to 500-599 as a deferred follow-up per Assumption §7.
- `Layer Integrity`: PASS. Plan explicitly maps `params.json` changes to Bicep and
  runbook, with manual topology alignment in HTML. Packet color scheme is HTML-only
  concern; no cross-layer propagation required.
- `Security`: PASS with prerequisite fix. HTTPS backend protocol fix is required
  before demo validation (T001 in Phase 2).
- `Determinism`: PASS. `uniqueString()` naming, deterministic routing behavior, and
  sequential notebook execution are preserved.

## Project Structure

### Documentation (this feature)

```text
specs/001-ai-gateway-routing-demo/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── cross-layer-contracts.md
│   └── module-interface-contracts.md
└── tasks.md
```

### Source Code (repository root)

```text
index.html
main.bicep
policy.xml
params.json
runbook.ipynb
biceps-explained.md
modules/
├── apim/v2/
│   ├── apim.bicep
│   └── inference-api.bicep
├── cognitive-services/v3/
│   ├── foundry.bicep
│   └── deployments.bicep
└── shared/v1/
    └── diagnostics.bicep
shared/
└── utils.py
```

**Structure Decision**: Preserve existing multi-layer repository structure and
deliver focused edits in-place without introducing framework folders or build
pipelines.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|

## Phase 0: Research Output Plan

- Produce `research.md` covering audit-driven decisions and unresolved operational
  choices.
- Resolve required decisions:
  - Critical audit findings handling strategy (prerequisite vs parallel).
  - `params.json` propagation model across layers.
  - Circuit breaker status-code scope.
  - APIM identity strategy boundaries.
  - Retry policy configurability strategy.
  - Packet color scheme specification (clarification session 2026-04-08: all resolved).
  - All-backends-unhealthy guard implementation (FR-013: clarification session 2026-04-08).

## Phase 1: Design Output Plan

- Produce `data-model.md` for cross-layer config entities (`aiServicesConfig`,
  `modelsConfig`, retry/circuit settings, visual runtime state including all-unhealthy
  guard, trace evidence records).
- Produce `contracts/` documentation for:
  - Cross-layer configuration and propagation contract (includes packet color scheme).
  - Bicep module interface and policy integration contract.
- Produce `quickstart.md` with a reproducible flow for local validation,
  deployment, runbook execution, and acceptance checks.

## Phase 2: Task Planning Approach (Input to /speckit.tasks)

- Organize tasks by story and by layer, preserving dependency order:
  1. Critical infra fixes (HTTPS protocol, strict deployment filter) as blockers.
  2. FR-013 all-backends-unhealthy guard in HTML layer (T019b).
  3. Cross-layer contract alignment updates.
  4. Validation and evidence tasks per layer.
- Include done criteria per task:
  - HTML: start/stop/failure/reset/all-unhealthy guard behavior verified manually.
  - Bicep: deploy succeeds and policy/backend definitions match contract.
  - Runbook: trace-backed attribution for baseline/extended/failover runs.

## Key Decisions

1. **Critical findings priority**: Treat HTTPS protocol and strict deployment
   filtering as prerequisites before enhancement tasks.
2. **Config propagation model**: `params.json` remains canonical; Bicep reads
   directly, runbook reads deployment outputs plus shared config context, HTML
   topology remains manually synchronized to preserve demo portability.
3. **Circuit breaker scope**: Keep current 429 behavior for initial parity, then
   add optional 500-599 expansion as a planned enhancement task with verification
   (explicit assumption added to spec: circuit breaker 500-599 is deferred).
4. **APIM identity strategy**: Keep SystemAssigned as default and explicitly
   document scope; defer UserAssigned support to a separate enhancement task.
5. **Retry parameterization**: Keep current policy defaults for this feature but
   document parameterization hooks as a follow-up hardening task.
6. **Packet color scheme (clarification 2026-04-08)**: Normal traffic = blue/green,
   failover reroute = orange/amber, all-backends-unhealthy backend nodes = red/orange.
   All values encoded as `SVG_CONFIG` constants; no scattered literals.
7. **FR-013 all-unhealthy guard**: Halt dispatch + red/orange node fill + reject Start.
   Guard clears on Reset. Measured within SC-001 (sixth interactive control action).
8. **Animation timing**: No explicit constraint — deferred to implementation defaults.

## Post-Design Constitution Re-Check

- `Plain-Stack`: PASS.
- `Config-Driven`: PASS — packet color constants in `SVG_CONFIG`, no literals.
- `Failure-Aware`: PASS — FR-013 guard adds all-unhealthy protection.
- `Layer Integrity`: PASS.
- `Security`: PASS.
- `Determinism`: PASS.
