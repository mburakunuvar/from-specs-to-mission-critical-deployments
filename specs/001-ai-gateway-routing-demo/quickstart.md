# Quickstart: Azure AI Gateway Backend Pool Demo

## Prerequisites

- Azure CLI authenticated to target subscription.
- Bicep deployment permissions in target resource group/subscription.
- Python 3.12 available for notebook environment.
- VS Code with Jupyter extension.

## 1. Validate HTML Layer

1. Open `index.html` in a browser.
2. Verify Start/Stop flow behavior.
3. Trigger Simulate Failure and confirm reroute to healthy backends only.
4. Trigger Reset and confirm all visual/runtime state is cleared.

## 2. Deploy Infrastructure Layer

1. Review `params.json` values for backend/service definitions.
2. Deploy `main.bicep` using Azure CLI.
3. Confirm deployment success for:
   - APIM instance and API resources.
   - Four Foundry/Cognitive Services backends.
   - Backend pool policy and diagnostics resources.
4. Confirm backend protocol is HTTPS and no secrets are embedded in templates.

## 3. Validate Runbook Layer

1. Open `runbook.ipynb` in VS Code.
2. Execute cells sequentially from Step 0 to Step 10d.
3. Verify baseline and extended traffic tests produce trace IDs.
4. Verify trace queries return authoritative backend attribution.
5. Execute deterministic failover override and restore sequence.

## 4. Acceptance Verification

- HTML controls and failure simulation pass manual checks.
- Bicep deployment completes without manual portal edits.
- Runbook Steps 7-9c demonstrate multi-backend routing evidence.
- Runbook Steps 10a-10d demonstrate deterministic single-endpoint failover and restore.
- Security posture verified: managed identity auth, least-privilege RBAC, HTTPS backends, no hardcoded secrets.

## 5. Troubleshooting Focus

- If deployment fails, first verify strict service mapping and backend protocol values.
- If traces are missing, validate APIM diagnostics setup and trace query inputs.
- If HTML behavior diverges from backend pool config, manually resync topology labels and health-routing assumptions.