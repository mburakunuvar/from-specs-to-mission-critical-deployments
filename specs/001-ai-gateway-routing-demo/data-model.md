# Data Model: Azure AI Gateway Backend Pool Demo

## Entity: AiServiceConfig

- Purpose: Defines each backend member in the APIM backend pool.
- Fields:
  - `name` (string, required, unique)
  - `endpoint` (string, required, must be HTTPS URL)
  - `region` (string, required)
  - `priority` (integer, required, allowed: 1..n)
  - `weight` (integer, required for same-priority groups)
  - `deploymentType` (string, optional)
  - `healthy` (boolean, runtime concept for HTML demo)
- Validation rules:
  - Endpoint MUST begin with `https://`.
  - Priority MUST be positive.
  - Name matching for deployment mapping MUST be strict equality (no substring).

## Entity: ModelsConfig

- Purpose: Defines model deployments associated with specific AI services.
- Fields:
  - `serviceName` (string, required; exact match to `AiServiceConfig.name`)
  - `modelName` (string, required)
  - `deploymentName` (string, required)
  - `skuName` (string, required)
  - `capacity` (integer, required)
- Validation rules:
  - `serviceName` MUST map to an existing AI service by exact key.
  - Capacity MUST be greater than zero.

## Entity: BackendPoolPolicy

- Purpose: Represents routing and resiliency policy intent enforced by APIM.
- Fields:
  - `retryStatusCodes` (list<int>, default `[429, 503]`)
  - `retryCount` (int, default `3`)
  - `retryIntervalSeconds` (int, default `0`)
  - `circuitBreakerStatusRanges` (list<string>, baseline includes `429`)
  - `poolSelectionMode` (string, fixed to priority/weight)
- Validation rules:
  - Retry count MUST be non-negative.
  - Status codes/ranges MUST be valid HTTP code values/ranges.

## Entity: VisualRuntimeState

- Purpose: Controls HTML simulation behavior.
- Fields:
  - `running` (boolean)
  - `roundRobinIndex` (integer)
  - `backendHealth` (map<string, boolean>)
  - `animationHandles` (list<string>)
- State transitions:
  - Idle -> Running when Start is triggered (blocked if all backends unhealthy).
  - Running -> Paused when Stop is triggered.
  - Running -> Running with modified health on Simulate Failure.
  - Running -> AllUnhealthy when Simulate Failure marks the last healthy backend as failed;
    packet dispatch halts and backend nodes change to red/orange fill.
  - AllUnhealthy -> Idle baseline on Reset (health map restored to all-true,
    node fills restored to healthy color).
  - Any state -> Idle baseline on Reset.
- Validation rules:
  - Start MUST be rejected when all values in `backendHealth` are false.
  - Reset MUST cancel all active `animationHandles` and restore `STATE` to initial defaults.

## Entity: RunbookExecutionContext

- Purpose: Encapsulates deployment/test runtime context in notebook flow.
- Fields:
  - `subscriptionId` (string)
  - `resourceGroupName` (string)
  - `deploymentName` (string)
  - `apimServiceName` (string)
  - `traceSessionIds` (list<string>)
  - `testBatchType` (enum: baseline, extended, deterministic-failover)
- Validation rules:
  - Required values MUST be present before test steps execute.

## Entity: TraceAttributionRecord

- Purpose: Captures authoritative backend attribution per request.
- Fields:
  - `requestId` (string)
  - `traceId` (string)
  - `backendHostname` (string)
  - `statusCode` (int)
  - `timestamp` (datetime string)

## Entity: SvgColorScheme

- Purpose: Defines the canonical packet and node color constants stored in `SVG_CONFIG` in `index.html`. All color values MUST be declared here and referenced by name — no inline literals in animation functions.
- Fields:
  - `packetColorNormal` (string, CSS color value, e.g., blue/green — normal traffic packets)
  - `packetColorFailover` (string, CSS color value, e.g., orange/amber — failover reroute packets)
  - `nodeColorHealthy` (string, CSS color value — default backend node fill)
  - `nodeColorFailed` (string, CSS color value — individual failed backend node fill)
  - `nodeColorAllUnhealthy` (string, CSS color value, red/orange — all-backends-unhealthy node fill)
- Validation rules:
  - All five fields MUST be present in `SVG_CONFIG` before any animation function references them.
  - `packetColorFailover` MUST visually distinguish from `packetColorNormal` (different hue family).
  - `nodeColorAllUnhealthy` MUST visually distinguish from `nodeColorFailed` (all-unhealthy is a system-level state, not a single-backend state).
  - `scenario` (enum: baseline, extended, deterministic-failover)
- Validation rules:
  - `traceId` and `backendHostname` MUST exist for authoritative attribution.

## Relationships

- `AiServiceConfig` 1..* -> `ModelsConfig` by exact `serviceName` match.
- `BackendPoolPolicy` applies to all `AiServiceConfig` entries.
- `VisualRuntimeState.backendHealth` keys correspond to configured backend names.
- `RunbookExecutionContext` produces many `TraceAttributionRecord` entries.

## Cross-Layer Notes

- Canonical config starts in `params.json` (`AiServiceConfig`, `ModelsConfig`).
- Bicep modules consume canonical config directly.
- Runbook consumes deployment outputs and aligned variable mapping.
- HTML topology mirrors backend pool shape manually and remains self-contained.