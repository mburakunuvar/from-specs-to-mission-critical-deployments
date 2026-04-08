# Module Interface Contracts

## `main.bicep`

- Responsibility: Orchestrates APIM, Foundry, deployments, diagnostics, and policy wiring.
- Input contract: Receives canonical configuration from `params.json`.
- Output contract: Exposes resource identifiers and runtime values needed by runbook.

## `modules/apim/v2/apim.bicep`

- Responsibility: Creates APIM service, identity, and subscriptions.
- Input contract:
  - APIM naming and SKU inputs.
  - Identity mode defaults to SystemAssigned for this feature scope.
- Output contract:
  - APIM resource identifiers and principal id used for RBAC assignment.

## `modules/apim/v2/inference-api.bicep`

- Responsibility: Creates inference API, backend resources, backend pool, and applies policy.
- Input contract:
  - Backend entries from `aiServicesConfig`.
  - Policy document content from `policy.xml`.
- Behavioral contract:
  - Backend protocol MUST be HTTPS.
  - Retry/failover behavior MUST align with documented status handling.

## `modules/cognitive-services/v3/foundry.bicep`

- Responsibility: Provisions Foundry accounts/projects and role assignments.
- Input contract:
  - Service definitions from canonical config.
- Output contract:
  - Resource names/ids consumed by deployment and policy modules.

## `modules/cognitive-services/v3/deployments.bicep`

- Responsibility: Deploys models to Foundry services.
- Input contract:
  - Model definitions keyed to exact service names.
- Behavioral contract:
  - Service-to-model mapping MUST use strict key equality, not substring matching.

## `modules/shared/v1/diagnostics.bicep`

- Responsibility: Creates/links Log Analytics and App Insights diagnostics resources.
- Input contract:
  - Diagnostics toggle and workspace/application settings.

## `policy.xml`

- Responsibility: Encodes routing retry and on-error behavior.
- Contract:
  - Must remain external to Bicep for clarity and governance.
  - Must preserve retry semantics on 429/503 for baseline behavior.