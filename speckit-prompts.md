# Spec-Kit Prompts

## /speckit.constitution

```
This project has three layers that must be governed by distinct but aligned principles:

1. HTML App Code (index.html) — A single-page SVG animation demo visualizing Azure AI Gateway routing. Uses vanilla HTML/CSS/JS only, no frameworks. Architecture: SVG_CONFIG (static constants) and STATE (mutable runtime) at the top, small pure SVG rendering functions, separate animation logic, deterministic round-robin routing across healthy backends only. All coordinates and styles live in SVG_CONFIG. SVG layer order matters (packets/labels above base elements).

2. Bicep Infra Code (main.bicep + modules/) — Infrastructure-as-Code deploying APIM + AI Foundry backend pool with priority-weighted routing and retry/circuit-breaker policies. Modules are versioned in folders (v2, v3). Every parameter uses @description decorators. Resource naming uses uniqueString() with deterministic suffixes. Authentication is APIM managed identity with RBAC role assignments. Policy XML is loaded from a separate file (policy.xml).

3. Jupyter Runbook (runbook.ipynb + shared/utils.py) — End-to-end lab notebook with numbered steps (Step 0 through Step 10d). Uses Azure CLI for deployments, Python SDK (openai, requests) for testing, pandas+matplotlib for visualization. Shared utilities in shared/utils.py provide ANSI-colored output helpers and Azure CLI wrappers. Credentials come from Azure CLI context, never hardcoded.

Core principles to encode:
- No frameworks or build tooling — plain HTML/CSS/JS, standard Bicep, vanilla Python
- Config-driven architecture — SVG_CONFIG, aiServicesConfig arrays, params.json
- Failure-aware by design — retry on 429/503, circuit breakers, round-robin only healthy backends
- Layered module structure — Bicep modules versioned and composable, shared Python utils reusable
- Demo-first quality — clear step numbering, visual proof of routing, authoritative APIM trace validation
- Security defaults — HTTPS backends, managed identity auth, RBAC least privilege, no hardcoded secrets
- Deterministic behavior — reproducible routing, uniqueString naming, sequential notebook flow
```

## /speckit.specify

```
Azure AI Gateway with Backend Pool Load Balancing — a three-layer demo that provisions, visualizes, and validates priority-weighted routing across multiple AI Foundry endpoints behind Azure API Management.

LAYER 1 — HTML App Code (index.html):
Single-page SVG animation demo (vanilla HTML/CSS/JS, no frameworks). Visualizes the Client → APIM Gateway → Backend Pool request flow. SVG_CONFIG holds all static coordinates and styles; STATE holds mutable runtime state (running flag, round-robin index, backend health, animation handles). Four backend nodes represent the pool members (PTU DZ swedencentral, PayGo DZ swedencentral, PayGo DZ germanywestcentral, PayGo Global germanywestcentral). Features: Start/Stop flow, Simulate Failure (marks next healthy backend as failed and reroutes), Reset. Routing is deterministic round-robin across healthy backends only; failover visually reroutes packets with distinct color. SVG layer order ensures packets and labels render above base elements.

LAYER 2 — Bicep Infra Code (main.bicep + modules/apim/v2/ + modules/cognitive-services/v3/ + modules/shared/v1/ + policy.xml + params.json):
Infrastructure-as-Code deploying: (a) APIM Basicv2 instance with managed identity, subscriptions, and App Insights logger; (b) four AI Foundry/Cognitive Services accounts with gpt-4o-mini GlobalStandard deployments and RBAC role assignments (Cognitive Services User for APIM principal, AI Project Manager for deployer); (c) inference API with backend pool using priority (1/2/2/3) and weight (50/50 for priority-2) routing; (d) policy.xml applying set-backend-service + retry on 429/503 (count=3) + circuit breaker; (e) Log Analytics + App Insights diagnostics. Modules are versioned (v2, v3). Resource naming uses uniqueString(). All parameters use @description decorators. Authentication is APIM managed identity with RBAC — no hardcoded secrets.

LAYER 3 — Jupyter Runbook (runbook.ipynb + shared/utils.py):
End-to-end lab notebook (Steps 0–10d) that: sets up Python venv and dependencies; authenticates via Azure CLI; creates resource group; deploys main.bicep; runs baseline (5 req) and extended (20 req) traffic tests capturing response headers and APIM trace IDs; visualizes routing with pandas+matplotlib; queries APIM listTrace API for authoritative backend attribution; runs deterministic failover test (override pool to single endpoint, run 5 req, restore original pool). shared/utils.py provides ANSI-colored output helpers, Azure CLI wrappers (run, get_resources, cleanup_resources), APIM trace/debug credential retrieval, and policy update utilities.

CROSS-LAYER CONTRACTS:
- params.json is the single source of truth for aiServicesConfig (4 endpoints with priority/weight), modelsConfig, apimSku, subscriptions, and diagnostics toggle
- The HTML demo mirrors the same 4-backend pool topology defined in params.json
- The runbook deploys the Bicep stack and then validates the routing behavior the HTML demo visualizes
- All three layers share the same failure-aware design: retry on 429/503, circuit breaker, round-robin only healthy backends

ACCEPTANCE CRITERIA:
- HTML demo: start/stop works, failure simulation reroutes correctly, reset clears all state
- Bicep: deploys APIM + 4 Foundry endpoints + backend pool + policy with zero manual steps
- Runbook: Steps 7–9c prove multi-backend routing; Steps 10a–10d prove deterministic single-endpoint failover and restore
- Security: managed identity auth, RBAC least privilege, no hardcoded secrets, HTTPS backends
- All layers remain plain-stack: vanilla JS, standard Bicep, vanilla Python — no frameworks or build tools
```

## /speckit.plan

```
Plan the implementation of the Azure AI Gateway Backend Pool Load Balancing feature across all three project layers. Use the spec produced by /speckit.specify as input.

TECHNICAL CONTEXT:
- Language/Version: JavaScript (ES6+ vanilla), Bicep (Azure CLI 2.x), Python 3.12
- Primary Dependencies: None for HTML; Azure Bicep CLI for infra; openai, requests, pandas, matplotlib for runbook
- Storage: N/A (stateless demo; Azure resources provisioned at deploy time)
- Testing: No test runner — manual browser validation for HTML, Azure deployment validation for Bicep, sequential cell execution for runbook
- Target Platform: Browser (index.html), Azure cloud (Bicep), VS Code Jupyter (runbook)
- Project Type: Multi-layer demo — static web page + IaC templates + lab notebook
- Constraints: No frameworks, no build tools, no hardcoded secrets, HTTPS-only backends

PROJECT STRUCTURE (existing — plan must preserve):
├── index.html                          # Layer 1: SVG animation demo
├── main.bicep                          # Layer 2: orchestrator
├── modules/
│   ├── apim/v2/
│   │   ├── apim.bicep                  # APIM service + identity + subscriptions
│   │   └── inference-api.bicep         # API + backends + pool + policy + circuit breaker
│   ├── cognitive-services/v3/
│   │   ├── foundry.bicep               # AI Foundry accounts + RBAC + projects
│   │   └── deployments.bicep           # Model deployments per account
│   └── shared/v1/
│       └── diagnostics.bicep           # Log Analytics + App Insights
├── policy.xml                          # APIM retry/routing policy
├── params.json                         # Single source of truth for all config
├── runbook.ipynb                       # Layer 3: Steps 0–10d lab notebook
├── shared/utils.py                     # Python helpers (run, get_resources, traces, cleanup)
└── biceps-explained.md                 # Audit doc with findings and checklists

CONSTITUTION CHECK GUIDANCE — verify each principle against the plan:
- Plain-Stack: no new dependencies or build tooling introduced in any layer
- Config-Driven: SVG_CONFIG for HTML, params.json/aiServicesConfig for Bicep, notebook variables for runbook
- Failure-Aware: retry on 429/503, circuit breaker in inference-api.bicep, round-robin only healthy backends in HTML demo
- Layer Integrity: changes to params.json ripple to Bicep deployment and runbook variables; HTML demo topology mirrors params.json but is self-contained
- Security: APIM managed identity + Cognitive Services User RBAC, no secrets in code, HTTPS backends
- Determinism: uniqueString() naming, sequential notebook steps, reproducible round-robin routing

IMPLEMENTATION PHASES TO PLAN:
Phase 0 — Research: Identify any open questions from the spec (audit findings in biceps-explained.md, backend protocol fix, deployment filter fix)
Phase 1 — Design: Define cross-layer contracts (params.json schema, Bicep module interfaces, runbook config variables, HTML SVG_CONFIG alignment), data model (aiServicesConfig shape, modelsConfig shape), and quickstart path
Phase 2 — Tasks: Break into dependency-ordered tasks per layer with clear done-criteria (this feeds /speckit.tasks)

KEY DECISIONS TO DOCUMENT IN THE PLAN:
- Whether to address Critical audit findings (HTTPS backend protocol, deployment substring filter) as prerequisites or parallel tasks
- How params.json changes propagate: Bicep reads directly, runbook reads deployment outputs, HTML is manually aligned
- Circuit breaker scope: current 429-only vs recommended 500-599 range
- APIM identity strategy: SystemAssigned-only (current) vs UserAssigned support
- Retry parameterization: keep hardcoded policy.xml values or make configurable via Bicep params
```

## /speckit.tasks

```
Generate dependency-ordered tasks for the Azure AI Gateway Backend Pool Load Balancing feature. Use the plan.md and spec.md as input. Organize tasks by layer and user story.

LAYER-SPECIFIC FILE PATHS (use exact paths in every task):
- Layer 1 (HTML):    index.html
- Layer 2 (Bicep):   main.bicep, modules/apim/v2/apim.bicep, modules/apim/v2/inference-api.bicep, modules/cognitive-services/v3/foundry.bicep, modules/cognitive-services/v3/deployments.bicep, modules/shared/v1/diagnostics.bicep, policy.xml, params.json
- Layer 3 (Runbook): runbook.ipynb, shared/utils.py

TASK GROUPING — organize into these phases:

Phase 1 — Constitution Compliance:
- T00A: Verify plain-stack compliance (no frameworks added to any layer)
- T00B: Verify config sources of truth (SVG_CONFIG, params.json, notebook variables)
- T00C: Verify failure-aware behavior (429/503 retry, circuit breaker, healthy-only routing)
- T00D: Verify security posture (managed identity, RBAC, no secrets, HTTPS)
- T00E: Verify determinism (uniqueString naming, round-robin, sequential steps)

Phase 2 — Critical Fixes (blocking prerequisites from biceps-explained.md audit):
- Fix APIM backend protocol from http to https in modules/apim/v2/inference-api.bicep
- Fix model deployment substring filter to strict equality in modules/cognitive-services/v3/deployments.bicep
- These block all Layer 2 and Layer 3 validation tasks

Phase 3 — Layer 2 Bicep Infrastructure (user stories: deploy APIM, deploy Foundry, configure routing):
- Tasks for modules/apim/v2/apim.bicep (APIM service, identity, subscriptions, logger)
- Tasks for modules/cognitive-services/v3/foundry.bicep (4 accounts, RBAC, projects)
- Tasks for modules/apim/v2/inference-api.bicep (API, backends, pool with priority/weight, circuit breaker)
- Tasks for policy.xml (set-backend-service, retry on 429/503)
- Tasks for modules/shared/v1/diagnostics.bicep (Log Analytics, App Insights)
- Tasks for params.json (validate schema: aiServicesConfig with priority/weight, modelsConfig, apimSku)
- Validation: az deployment group create succeeds with zero manual steps

Phase 4 — Layer 1 HTML Demo (user stories: visualize routing, simulate failure, reset):
- Tasks for SVG_CONFIG updates in index.html (4 backends matching params.json topology)
- Tasks for STATE and round-robin routing logic (healthy-only selection)
- Tasks for animation functions (packet flow, failover reroute with distinct color)
- Tasks for control buttons (Start/Stop, Simulate Failure, Reset)
- Validation: open index.html in browser, verify start/stop/failure/reset behavior

Phase 5 — Layer 3 Runbook (user stories: deploy infra, test routing, prove failover):
- Tasks for Steps 0–6 in runbook.ipynb (setup, auth, resource group, deploy main.bicep)
- Tasks for Steps 7–8c (baseline 5-request test, header capture, APIM trace attribution, visualization)
- Tasks for Steps 9–9c (extended 20-request test, failover observation, trace attribution)
- Tasks for Steps 10–10d (deterministic failover: snapshot pool, override to single endpoint, test, restore)
- Tasks for shared/utils.py (run, get_resources, cleanup_resources, get_debug_credentials, get_trace)
- Validation: sequential cell execution completes Steps 0–10d without errors

Phase 6 — Cross-Layer Polish:
- Verify params.json topology matches SVG_CONFIG backend definitions in index.html
- Verify runbook deployment outputs align with params.json inputs
- Update biceps-explained.md if Critical/High findings are resolved
- Verify README.md accuracy against current implementation

DEPENDENCY RULES:
- Phase 1 has no dependencies (can start immediately)
- Phase 2 depends on Phase 1 completion
- Phase 3 depends on Phase 2 (critical fixes must land before infra validation)
- Phase 4 can run in parallel with Phase 3 (HTML is self-contained)
- Phase 5 depends on Phase 3 (runbook deploys the Bicep stack)
- Phase 6 depends on Phases 3, 4, and 5

PARALLEL OPPORTUNITIES:
- Within Phase 3: APIM module tasks [P] with Foundry module tasks (different files)
- Within Phase 4: SVG_CONFIG tasks [P] with animation tasks (different code sections)
- Within Phase 5: shared/utils.py tasks [P] with early notebook setup cells
- Phase 4 (HTML) runs fully in parallel with Phase 3 (Bicep)
```




## Test Step Reference

The runbook tests traffic routing across four AI Foundry backends behind an APIM gateway. Here's how each step builds on the previous:

**Phase 1: Baseline (5 requests)**
- **Step 7:** Run 5 test requests; capture response headers (`x-ms-region`, optional endpoint hints) and APIM trace IDs
- **Step 8a:** Quick visualization of what the client sees (best-effort: endpoint names if available, else regions)
- **Step 8b:** Query APIM traces via `listTrace` API to get **exact authoritative backend attribution**  
- **Step 8c:** Pretty chart of Step 8b data — use this for live demos

**Phase 2: Extended (20 requests; triggers failover)**
- **Step 9:** Run 20 test requests; same capture as Step 7 to observe failover behavior
- **Step 9a:** Quick visualization (best-effort, may show regions only if APIM doesn't expose exact target)
- **Step 9b:** Query APIM traces for exact backend attribution across all 20 requests  
- **Step 9c:** Pretty chart of Step 9b data — authoritative proof of which backends handled traffic

**Phase 3: Deterministic failover (5 requests; forces Endpoint 4)**
- **Step 10:** Overview, prerequisites, and safety notes — temporary override scope explained
- **Step 10a:** Snapshot the current APIM backend pool + apply Endpoint-4-only override
- **Step 10b:** Run 5 targeted requests while override is active; capture trace IDs
- **Step 10c:** Query APIM traces — confirms all 5 requests routed exclusively to Endpoint 4
- **Step 10d:** Restore original backend pool — APIM returns to full priority-based routing

**When to use which:**
- **For testing/iteration:** Runs Steps 8a + 9a (fast, no backend queries needed)
- **For live demo:** Run the full chain (8b + 8c for baseline proof; 9b + 9c for extended failover proof; 10a–10d for deterministic Endpoint 4 failover proof)

| Step | Purpose | Data source | Accuracy |
|------|---------|-------------|----------|
| **7** | Baseline traffic test | Response headers + APIM trace IDs | Client-visible signals |
| **8a** | Baseline visualization (quick) | Headers + trace IDs | Best-available (endpoint names if hints present, else regions) |
| **8b** | Baseline diagnostics | APIM traces via `listTrace` API | **Exact backend hostnames** |
| **8c** | Baseline visualization (authoritative) | Step 8b results | **Exact match** to 8b data |
| **9** | Extended traffic test (20 req) | Response headers + APIM trace IDs | Client-visible signals |
| **9a** | Extended visualization (quick) | Headers + trace IDs | Best-available |
| **9b** | Extended diagnostics | APIM traces via `listTrace` API | **Exact backend hostnames** |
| **9c** | Extended visualization (authoritative) | Step 9b results | **Exact match** to 9b data |
| **10** | Failover test overview + safety notes | — | — |
| **10a** | Snapshot pool + apply Endpoint-4-only override | APIM management API | **Exact APIM backend pool state** |
| **10b** | Deterministic failover traffic (5 req) | Response headers + APIM trace IDs | Client-visible signals |
| **10c** | Failover attribution (authoritative) | APIM traces via `listTrace` API | **Exact backend hostnames** |
| **10d** | Restore original backend pool | APIM management API | **Exact APIM backend pool state** |



## Provisioned Resources

All resource names generated by this deployment are within Azure limits:

| Resource | Pattern | Status | Use case |
|---|---|---|---|
| Resource Group | `rg-gh-spec-kit-to-foundry-mission-critical` | ✅ | Container for all deployment resources |
| ARM Deployment | `gh-spec-kit-to-foundry-mission-critical` | ✅ | Tracks the Bicep deployment lifecycle in ARM |
| APIM instance | `apim-<13-char hash>` | ✅ | AI Gateway — routes and load balances inference traffic |
| Cognitive Services | `Endpoint4-PayGo-Global-Germany-<13-char hash>` | ✅ | AI Foundry account hosting model deployments |
| Custom subdomain | same as above, lowercased | ✅ | Unique HTTPS endpoint URL for each AI Foundry account |
| AI Project | `ghspeckit-to-foundry-Endpoint4-PayGo-Global-Germany` | ✅ | AI Foundry project scoped to each account |
| Log Analytics | `law-<13-char hash>` | ✅ | Stores diagnostic logs and metrics |
| App Insights | `appi-<13-char hash>` | ✅ | Traces exact backend calls per request |

