# Research: Azure AI Gateway Backend Pool Demo

## Decision 1: Critical audit findings scheduling

- Decision: Treat HTTPS backend protocol fix and strict deployment filter fix as
  prerequisites before broader cross-layer enhancement tasks.
- Rationale: Both findings are marked critical and can directly impact deployment
  safety or runtime correctness.
- Alternatives considered:
  - Run fixes in parallel with all other work: rejected due to higher integration
    risk and possible rework.
  - Defer fixes until after demo flow implementation: rejected because acceptance
    evidence would be less trustworthy.

## Decision 2: `params.json` propagation strategy

- Decision: Keep `params.json` as the source of truth; Bicep reads directly,
  runbook consumes deployment outputs and aligned config variables, HTML topology is
  manually mirrored to preserve a self-contained static demo.
- Rationale: This matches existing architecture while avoiding framework/tooling
  additions.
- Alternatives considered:
  - Auto-generate HTML topology from deployment outputs: rejected for added tooling
    complexity in a plain-stack repo.
  - Duplicate config definitions per layer: rejected for drift risk.

## Decision 3: Circuit breaker status range scope

- Decision: Preserve current 429-only breaker behavior as baseline and plan an
  optional extension path for 500-599 once baseline parity tests pass.
- Rationale: Keeps behavior stable for current demo while creating a clear
  hardening path.
- Alternatives considered:
  - Immediately switch to 429 + 500-599: rejected for higher behavior-change scope
    in same pass as critical fixes.
  - Keep 429-only permanently: rejected as it limits resilience for transient 5xx.

## Decision 4: APIM identity strategy

- Decision: Keep SystemAssigned identity as primary supported mode for this feature
  and document UserAssigned as future enhancement scope.
- Rationale: Current implementation and runbook assumptions already align with
  SystemAssigned and least-privilege RBAC flow.
- Alternatives considered:
  - Full UserAssigned support now: rejected due to added branching complexity in
    role assignment/output handling.
  - Hardcode identity assumptions without documentation: rejected for maintainability.

## Decision 5: Retry parameterization

- Decision: Keep current `policy.xml` retry values (`count=3`, `interval=0`) in this
  feature and document configurable parameterization as follow-up work.
- Rationale: Maintains deterministic demo behavior and avoids broad policy plumbing
  changes in the same cycle.
- Alternatives considered:
  - Parameterize retry immediately through Bicep params: rejected for scope growth.
  - Leave retry undocumented: rejected because it reduces operational clarity.

## Decision 6: Open questions from spec and audit

- Decision: Mark all planning clarifications as resolved in this phase; no remaining
  `NEEDS CLARIFICATION` blockers.
- Rationale: Technical context, security posture, and phase ordering are now explicit.
- Alternatives considered:
  - Defer unresolved questions to task generation: rejected because it weakens
    implementation sequencing.

## Decision 7: Packet color scheme for SVG animation (clarification 2026-04-08)

- Decision: Encode three distinct color states as `SVG_CONFIG` constants — blue/green
  for normal traffic packets, orange/amber for failover reroute packets, and red/orange
  fill for backend nodes in the all-unhealthy state.
- Rationale: Color is the simplest SVG attribute change with no structural difference
  to the animation path; immediately legible to a live audience; reuses failure-color
  palette consistently across both failover and all-unhealthy states.
- Alternatives considered:
  - Dashed stroke / outlined packets for failover: rejected in favor of color, which
    is more legible at presenter distance.
  - Text label near gateway for all-unhealthy indicator: rejected in favor of per-node
    color change, which localizes the signal to the failing element.
  - Animated pulse/glow for rerouted packets: rejected for added implementation
    complexity in a plain-JS constraint.

## Decision 8: FR-013 all-backends-unhealthy guard and SC-001 scope (clarification 2026-04-08)

- Decision: When all entries in `STATE.backendHealth` are false, halt packet dispatch
  immediately, apply red/orange fill to all backend nodes, and reject Start button
  presses until Reset restores health. Include this guard verification within SC-001
  as a sixth interactive control action.
- Rationale: Keeps acceptance scope consolidated to a single browser-validation
  criterion (SC-001) without adding a sixth success criterion. Guard clears on Reset,
  maintaining deterministic state machine.
- Alternatives considered:
  - Add a separate SC-006 for FR-013: rejected to avoid fragmenting the acceptance
    evidence surface for a single interactive state.
  - Leave guard untested (covered implicitly by Simulate Failure): rejected because
    the all-unhealthy case is a distinct state unreachable by pressing Simulate Failure
    against one backend.