# Tasks: Azure AI Gateway Backend Pool Demo

**Input**: Design documents from `/specs/001-ai-gateway-routing-demo/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Branch**: `001-ai-gateway-routing-demo` | **Date**: 2026-04-08 | **Last updated**: 2026-04-08 (refresh: spec clarification session — FR-013 color spec, SvgColorScheme entity, CA-006, SC-001 extended)
**Organization**: Tasks grouped by user story to enable independent implementation, testing, and delivery.

---

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[US1]**: User Story 1 — Visualize Gateway Routing Flow (`index.html`)
- **[US2]**: User Story 2 — Provision Mission-Critical Routing Stack (Bicep)
- **[US3]**: User Story 3 — Validate Routing with Trace Evidence (Runbook)
- Constitution Compliance and Critical Fixes phases have no story label — they are cross-cutting prerequisites

---

## Phase 1: Constitution Compliance (Mandatory)

**Purpose**: Establish non-negotiable guardrails before any feature work begins. Verify that existing code already meets project principles, and document any gaps to address before Phase 2.

**No dependencies — can start immediately.**

- [ ] T00A Verify plain-stack compliance: confirm no frameworks, build tools, or new dependencies appear in `index.html`, `main.bicep`, all `modules/` files, `runbook.ipynb`, and `shared/utils.py`; confirm module versioning directory names (`apim/v2`, `cognitive-services/v3`, `shared/v1`) are unchanged
- [ ] T00B Verify config sources of truth: confirm `SVG_CONFIG` holds all display constants in `index.html` including the five `SvgColorScheme` color constants (`packetColorNormal`, `packetColorFailover`, `nodeColorHealthy`, `nodeColorFailed`, `nodeColorAllUnhealthy`); confirm `aiServicesConfig` with priority/weight is the authoritative pool definition in `params.json`; confirm deployment variable assignments in `runbook.ipynb` derive from deployment outputs
- [ ] T00C Verify failure-aware behavior: confirm policy retry on 429/503 with count=3 in `policy.xml`, circuit breaker rule on 429 in `modules/apim/v2/inference-api.bicep`, and round-robin restricted to healthy backends only in `index.html`
- [ ] T00D Verify security posture: confirm APIM managed identity (SystemAssigned) in `modules/apim/v2/apim.bicep`, Cognitive Services User RBAC assignment in `modules/cognitive-services/v3/foundry.bicep`, no hardcoded secrets or credentials in any file across all three layers, and backend protocol not yet HTTPS (gap to fix in Phase 2)
- [ ] T00E Verify determinism: confirm `uniqueString()` used for all resource naming in `main.bicep`, round-robin index starts at 0 and advances predictably in `index.html`, and Steps 0–10d are sequentially numbered in `runbook.ipynb`

**Checkpoint**: Constitution compliance documented — any gaps flagged here become Phase 2 tasks.

---

## Phase 2: Critical Fixes (Blocking Prerequisites)

**Purpose**: Resolve Critical-severity audit findings that block all Layer 2 and Layer 3 validation. Must complete before any user story validation tasks can run.

**⚠️ BLOCKS**: All Bicep deployment validation (Phase 3) and runbook steps that deploy infrastructure (Phase 5).

**Depends on Phase 1 completion.**

- [ ] T001 Fix APIM backend protocol from `http` to `https` for all backend resource entries in `modules/apim/v2/inference-api.bicep` (Critical finding — Contract 4 requires HTTPS, data-model requires endpoint begins with `https://`)
- [ ] T002 Fix model deployment service-name mapping from substring match to strict key equality in `modules/cognitive-services/v3/deployments.bicep` (Critical finding — data-model `ModelsConfig.serviceName` requires exact match to `AiServiceConfig.name`)

**Checkpoint**: Critical fixes merged — Layer 2 and Layer 3 validation tasks can now proceed.

---

## Phase 3: User Story 2 — Provision Mission-Critical Routing Stack (Priority: P1)

**Goal**: Deliver a fully parameterized Bicep stack that provisions APIM, four AI Foundry backends, routing policy, and diagnostics in a single automated run with zero manual steps.

**Independent Test**: Run `az deployment group create --what-if` with `params.json`; verify no errors and that all expected resource types are represented. Confirm `az deployment group create` succeeds end-to-end.

**Depends on Phase 2 (critical fixes must be in place before deployment is valid).**

### Implementation for User Story 2

- [ ] T003 [P] [US2] Review and validate APIM service definition in `modules/apim/v2/apim.bicep` — confirm Basicv2 SKU, SystemAssigned identity, subscription creation, App Insights logger binding, and `@description` on all parameters
- [ ] T004 [P] [US2] Review and validate Foundry accounts, RBAC role assignments, and AI projects in `modules/cognitive-services/v3/foundry.bicep` — confirm four accounts, Cognitive Services User for APIM principal, AI Project Manager for deployer, and strict account-to-project binding
- [ ] T005 [US2] Validate inference API backend pool configuration in `modules/apim/v2/inference-api.bicep` — confirm four backend entries with correct priority (1, 2, 2, 3) and weight (50/50 for same-priority pair) sourced from `aiServicesConfig` in `params.json`
- [ ] T006 [US2] Validate circuit breaker rule in `modules/apim/v2/inference-api.bicep` — confirm 429-only baseline behavior, document optional 500-599 extension path as a comment or TODO per Key Decision 3 in `plan.md`
- [ ] T007 [P] [US2] Validate model deployment entries in `modules/cognitive-services/v3/deployments.bicep` — confirm all deployment names, SKUs, and capacities match `modelsConfig` entries in `params.json` using strict equality after T002 fix
- [ ] T008 [P] [US2] Validate APIM retry and routing policy in `policy.xml` — confirm `set-backend-service` selector targets the backend pool, retry triggers on 429 and 503, retry count equals 3, and retry interval is 0 seconds per `BackendPoolPolicy` defaults
- [ ] T009 [P] [US2] Validate Log Analytics workspace and App Insights resource definitions in `modules/shared/v1/diagnostics.bicep` — confirm resource type, SKU, workspace-to-insights linking, and diagnostics toggle parameter
- [ ] T010 [US2] Validate `params.json` schema completeness — confirm `aiServicesConfig` array has four entries each with `name`, `endpoint` (HTTPS), `region`, `priority`, `weight`; confirm `modelsConfig`, `apimSku`, subscription settings, and diagnostics toggle are present and non-empty
- [ ] T011 [US2] Validate `main.bicep` orchestration — confirm all module references use correct relative paths and versions (v2, v3, v1), confirm output bindings expose resource identifiers for runbook consumption, and confirm `uniqueString()` naming pattern is consistent
- [ ] T012 [US2] Execute `az deployment group create --what-if --parameters params.json` to validate full deployment plan resolves without errors; document the output as acceptance evidence for US2

**Checkpoint**: User Story 2 complete — APIM + Foundry + routing policy + diagnostics deployable and validated end-to-end.

---

## Phase 4: User Story 1 — Visualize Gateway Routing Flow (Priority: P1)

**Goal**: Deliver a single-page SVG animation that shows client-to-gateway-to-backend packet flow with working start/stop, failure simulation with rerouting, and reset.

**Independent Test**: Open `index.html` directly in browser (no server needed). Verify start/stop toggles packet flow, failure simulation reroutes with distinct visual color, and reset clears all animations and restores initial state across five consecutive runs.

**No dependency on Phase 3 — HTML is self-contained. Can run fully in parallel with Phase 3.**

### Implementation for User Story 1

- [ ] T013 [P] [US1] Review and update `SVG_CONFIG` in `index.html` — confirm (a) four backend node definitions matching the pool topology in `params.json`: PTU DZ swedencentral (priority 1), PayGo DZ swedencentral (priority 2, weight 50), PayGo DZ germanywestcentral (priority 2, weight 50), PayGo Global germanywestcentral (priority 3); and (b) all five `SvgColorScheme` color constants are present: `packetColorNormal` (blue/green), `packetColorFailover` (orange/amber), `nodeColorHealthy`, `nodeColorFailed`, `nodeColorAllUnhealthy` (red/orange) — Contract 6 requires all colors declared here, no inline literals
- [ ] T014 [P] [US1] Validate `STATE` object structure in `index.html` — confirm fields `running`, `roundRobinIndex`, `backendHealth` (map keyed to backend names), and `animationHandles` (list of timer references) are present and initialized to correct defaults
- [ ] T015 [US1] Implement and validate round-robin routing logic in `index.html` — confirm selection advances through healthy backends only, skips failed backends, wraps at end of list, and produces deterministic order across consecutive calls
- [ ] T016 [P] [US1] Validate packet animation functions in `index.html` — confirm SVG packet elements are created using `SVG_CONFIG.packetColorNormal` (blue/green) for normal traffic, follow the Client → Gateway → Backend path, and are removed on completion; confirm packets and labels render above base SVG elements (correct layer order); confirm no inline color literals appear in animation functions (all colors reference `SVG_CONFIG` constants)
- [ ] T017 [US1] Implement and validate failover reroute animation in `index.html` — confirm rerouted packets use `SVG_CONFIG.packetColorFailover` (orange/amber fill, distinct from blue/green normal packets) per FR-004; confirm the failed backend node fill changes to `SVG_CONFIG.nodeColorFailed`; confirm rerouted packets travel to the next healthy backend only
- [ ] T018 [P] [US1] Validate Start/Stop button behavior in `index.html` — confirm Start sets `STATE.running = true` and begins packet dispatch, Stop sets `STATE.running = false` and halts new packets while in-flight packets complete
- [ ] T019 [US1] Implement and validate Simulate Failure button in `index.html` — confirm it marks the next healthy backend as failed in `STATE.backendHealth`, updates visual state immediately, and subsequent packets route only to remaining healthy backends
- [ ] T019b [US1] Implement and validate all-backends-unhealthy guard in `index.html` (FR-013) — **Depends on T019**: test by pressing Simulate Failure on each backend in turn until all are marked failed; confirm that when all entries in `STATE.backendHealth` are false: (a) packet dispatch halts immediately, (b) all backend node fills change to `SVG_CONFIG.nodeColorAllUnhealthy` (red/orange), (c) pressing Start while all backends are failed is rejected with no new packets dispatched; confirm the guard is cleared and node fills restored to `SVG_CONFIG.nodeColorHealthy` on Reset
- [ ] T020 [US1] Implement and validate Reset button in `index.html` — confirm it cancels all active `animationHandles`, resets `STATE.running` to false, `STATE.roundRobinIndex` to 0, `STATE.backendHealth` to all-healthy, clears all packet/animation SVG elements, and restores all backend node fills to `SVG_CONFIG.nodeColorHealthy` (required by FR-013 guard clearance)
- [ ] T021 [US1] Manual browser validation for User Story 1 in `index.html` — perform five consecutive run sets covering all six SC-001 control actions: (1) start→observe blue/green routing, (2) stop→confirm halt, (3) fail→observe orange/amber reroute packets and failed node fill, (4) fail all→confirm red/orange node fill and Start rejection (FR-013 guard), (5) reset→confirm clean state and all-healthy fill restored, (6) repeat from (1); record acceptance evidence for SC-001

**Checkpoint**: User Story 1 complete — demo fully functional and independently verified in browser.

---

## Phase 5: User Story 3 — Validate Routing with Trace Evidence (Priority: P2)

**Goal**: Deliver a complete runbook (Steps 0–10d) that deploys the infrastructure, runs baseline/extended traffic tests, and produces authoritative trace-backed attribution evidence for routing, failover, and restore.

**Independent Test**: Execute all cells in `runbook.ipynb` sequentially from Step 0 through Step 10d without manual intervention; confirm each step cell completes without errors and Steps 7c, 8c, 9c, and 10c produce non-empty trace attribution results.

**Depends on Phase 3 (Bicep stack must deploy successfully before runbook validation steps).**

### Implementation for User Story 3

- [ ] T022 [P] [US3] Review and validate helper functions in `shared/utils.py` — confirm `run()` executes CLI commands and returns output, `get_resources()` queries resource group, `cleanup_resources()` handles resource deletion, `get_debug_credentials()` retrieves APIM trace credentials, and `get_trace()` calls the APIM listTrace API; confirm ANSI output coloring is present
- [ ] T023 [P] [US3] Review and update Steps 0–2 in `runbook.ipynb` — confirm Step 0 installs venv and dependencies from `requirements.txt`, Step 1 authenticates via `az login`/`az account set`, Step 2 sets subscription and region variables
- [ ] T024 [US3] Review and update Steps 3–5 in `runbook.ipynb` — confirm Step 3 creates or selects the resource group, Step 4 sets deployment name and output variable bindings, Step 5 assigns `apimServiceName`, `resourceGroupName`, and any other values needed by subsequent cells
- [ ] T025 [US3] Review and update Step 6 in `runbook.ipynb` — confirm the cell calls `az deployment group create --template-file main.bicep --parameters params.json`, captures output, and assigns deployment outputs to runbook context variables; confirm `RunbookExecutionContext` fields are fully populated after this step
- [ ] T026 [US3] Review and update Steps 7–7c in `runbook.ipynb` — confirm Step 7 sends 5 baseline requests via the `openai` SDK or `requests` library through the APIM gateway, Step 7a captures response headers including trace IDs, Step 7b logs raw results, Step 7c displays a pandas table of request/backend attribution
- [ ] T027 [US3] Review and update Steps 8–8c in `runbook.ipynb` — confirm Step 8 calls `get_debug_credentials()` and `get_trace()` for each baseline trace ID, Step 8a parses `backendHostname` from trace response, Step 8b builds `TraceAttributionRecord` per request, Step 8c renders a matplotlib visualization of backend distribution
- [ ] T028 [US3] Review and update Steps 9–9c in `runbook.ipynb` — confirm Step 9 sends 20 extended requests, Step 9a captures response headers and trace IDs, Step 9b calls `get_trace()` for each, Step 9c produces trace-attributed distribution visualization; confirm at least one failover/retry event is observable in the trace output
- [ ] T029 [US3] Review and update Steps 10–10d in `runbook.ipynb` — confirm Step 10 snapshots the current backend pool policy, Step 10a uses `update_policy()` or equivalent to override the pool to a single forced endpoint, Step 10b runs 5 targeted requests, Step 10c retrieves traces confirming 100% attribution to the forced endpoint, Step 10d restores the original pool policy and confirms routing resumes normally
- [ ] T030 [US3] Full sequential validation of `runbook.ipynb` — restart kernel, execute all cells from Step 0 to Step 10d in order, confirm zero errors; capture and record trace output tables from Steps 7c, 8c, 9c, and 10c as acceptance evidence for SC-003 and SC-004

**Checkpoint**: User Story 3 complete — runbook produces authoritative trace-backed evidence for all routing, failover, and restore scenarios.

---

## Phase 6: Cross-Layer Polish

**Purpose**: Verify cross-layer consistency and update documentation artifacts that span multiple user stories.

**Depends on Phases 3, 4, and 5 (all user stories complete).**

- [ ] T031 [P] Verify `params.json` backend topology matches `SVG_CONFIG` backend definitions in `index.html` — confirm all four backend names, regions, priorities, and weights are identical; document any discovered discrepancy as an acceptance blocker
- [ ] T032 [P] Verify runbook deployment output variable bindings in `runbook.ipynb` align with `params.json` input values — confirm `apimServiceName`, resource group, and endpoint values are consistent end-to-end
- [ ] T033 Update `biceps-explained.md` to mark Critical finding "HTTPS backend protocol" and Critical finding "deployment substring filter" as Resolved, referencing T001 and T002 task completion; mark High-severity findings that are now documented-and-deferred (circuit breaker scope, APIM identity) as "documented — deferred"; update any associated checklist items (satisfies FR-012 audit traceability)
- [ ] T034 Review `README.md` against current implementation — confirm layer descriptions, deployment instructions, and runbook step summary accurately reflect the delivered state; update any stale content (supports SC-002: accurate deployment documentation reduces first-attempt failure risk)

**Checkpoint**: All cross-layer checks passed and documentation is accurate — feature complete.

---

## Dependencies & Execution Order

### Phase Dependencies

| Phase | Name | Depends On | Can Parallelize With |
|-------|------|-----------|---------------------|
| Phase 1 | Constitution Compliance | — (start immediately) | Nothing — must run first |
| Phase 2 | Critical Fixes | Phase 1 | — |
| Phase 3 | Bicep Infrastructure [US2] | Phase 2 | Phase 4 (HTML is independent) |
| Phase 4 | HTML Demo [US1] | Phase 1 only | Phase 3 fully |
| Phase 5 | Runbook [US3] | Phase 3 | — |
| Phase 6 | Cross-Layer Polish | Phases 3 + 4 + 5 | — |

### User Story Dependencies

- **User Story 1 (P1 - HTML)**: Depends on Phase 1 (constitution) only. Fully independent of Bicep deployment. Can proceed immediately after Phase 1 completes.
- **User Story 2 (P1 - Bicep)**: Depends on Phase 2 (critical fixes in place). No dependency on US1. Infrastructure must be valid before runbook can prove behavior.
- **User Story 3 (P2 - Runbook)**: Depends on US2 (Bicep stack deployed and validated). Runbook Steps 0–5 can be prepared in parallel during Phase 3; validation steps (6–10d) depend on successful deployment.

### Within Phases — Parallel Opportunities

- **Phase 3 (Bicep)**: T003 [P] and T004 [P] (APIM module vs Foundry module — different files); T007 [P] with T008 [P] and T009 [P]
- **Phase 4 (HTML)**: T013 [P] and T014 [P] (SVG_CONFIG vs STATE — different code sections); T016 [P] and T018 [P]
- **Phase 5 (Runbook)**: T022 [P] (shared/utils.py) runs in parallel with T023 [P] (early notebook setup cells)
- **Phase 6 (Polish)**: T031 [P] and T032 [P] — different verification targets

### MVP Scope

For a minimal viable demonstration, deliver **User Story 1 only** (Phases 1 + 4):
- Phases 1 and 4 have no cloud dependency.
- HTML demo is self-contained and browser-testable without deployment.
- Full feature requires Phases 1–6 in dependency order.

---

## Implementation Strategy

1. **Start with compliance**: Phase 1 tasks T00A–T00E require only read access and produce documentation artifacts — assign immediately.
2. **Clear blockers fast**: Phase 2 (T001, T002) are small targeted edits to two Bicep files — complete these before branching implementation work.
3. **Parallelize layers**: Once Phase 2 is done, Phase 3 (Bicep) and Phase 4 (HTML) can proceed on separate branches or in separate work streams.
4. **Validate incrementally**: Each phase has an explicit checkpoint with defined acceptance evidence. Do not begin a downstream phase until the upstream checkpoint passes.
5. **Runbook last**: Phase 5 is the most dependent — it needs a live deployed stack. Prepare shared/utils.py (T022) and early runbook cells (T023) during Phase 3 to compress end-to-end cycle time.

---

## Validation Summary

| Layer | Validation Method | Acceptance Evidence |
|-------|------------------|---------------------|
| HTML (`index.html`) | Manual browser — open file directly | Five consecutive start/stop/fail/reset runs without error (SC-001); all-backends-unhealthy guard verified (FR-013) |
| Bicep (all modules) | `az deployment group create --what-if` + full deployment | Zero-error deployment, all resources present (SC-002) |
| Runbook (`runbook.ipynb`) | Sequential cell execution Steps 0–10d | Trace attribution tables from Steps 7c, 8c, 9c, 10c (SC-003, SC-004) |
| Security (all layers) | Manual review — no secrets, HTTPS, RBAC audit | Zero hardcoded credentials, HTTPS endpoints verified (SC-005) |

---

*Note: Tests are not included here — no test runner is configured in this project. Validation is performed manually per layer as documented above. See `quickstart.md` for the full end-to-end validation guide.*
