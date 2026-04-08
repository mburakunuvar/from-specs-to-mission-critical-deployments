# Cross-Layer Contracts

## Contract 1: Configuration Source of Truth

- Canonical file: `params.json`
- Canonical sections:
  - `aiServicesConfig`
  - `modelsConfig`
  - APIM and diagnostics settings
- Rules:
  - Bicep modules MUST consume these values directly.
  - Runbook variables MUST align with deployment outputs derived from these values.
  - HTML backend topology MUST mirror canonical backend pool shape (manual sync).

## Contract 2: Routing Behavior Consistency

- HTML behavior: deterministic round-robin across healthy backends only.
- APIM behavior: priority + weighted pool routing with retry logic on 429/503.
- Runbook proof: trace-backed attribution MUST confirm routing behavior for baseline,
  extended, and deterministic failover runs.

## Contract 3: Failure Handling Semantics

- Retry conditions: 429/503 baseline behavior.
- Circuit breaker: baseline 429 range; optional extension path to 500-599 documented.
- Failover mode in runbook: single-endpoint override MUST route all targeted requests
  to the forced endpoint until restore.

## Contract 4: Security and Identity

- Backend endpoints MUST be HTTPS.
- Gateway-to-backend authentication MUST use APIM managed identity.
- Role assignments MUST follow least privilege and avoid embedded secrets.

## Contract 5: Deterministic Execution

- Infrastructure naming MUST remain deterministic via `uniqueString()` patterns.
- Notebook steps MUST execute in documented sequence (Step 0-Step 10d).
- HTML reset MUST restore deterministic baseline state.

## Contract 6: Visual Color Scheme (HTML layer only)

- All packet and node color constants MUST be declared in `SVG_CONFIG` in `index.html`; no inline color literals in animation functions.
- Color conventions (canonical values; exact CSS values chosen by implementer but must satisfy hue-family constraints from data-model `SvgColorScheme`):
  - Normal traffic packets: blue/green hue family.
  - Failover reroute packets: orange/amber hue family (visually distinct from normal).
  - Individual failed backend node fill: distinct from healthy fill.
  - All-backends-unhealthy backend node fill: red/orange (visually distinct from single-backend-failed state).
- This contract is scoped to `index.html` only; Bicep and runbook layers have no dependency on packet color choices.