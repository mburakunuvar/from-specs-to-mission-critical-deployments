# from-specs-to-mission-critical-deployments
How to use Github spec-kit to build an AI App that'll use multiple MS Foundry Models behind Azure AI Gateway

## Why Spec-Kit?

This project uses [GitHub Spec-Kit](https://github.com/github/spec-kit) to make the development process **reproducible and AI-assisted**. Spec-Kit is a spec-driven development workflow toolkit that structures how AI agents (like Copilot) build and modify code.

### What Spec-Kit provides

| Concept | What it provides |
|---------|-----------------|
| **Constitution** | Project principles and conventions that AI agents follow |
| **Specs** | Templates for writing feature requirements |
| **Plans** | Structured implementation plans derived from specs |
| **Tasks** | Breakdowns with dependencies for execution |
| **Integrations** | Hooks into AI agents (Copilot, etc.) |

### What it solves for reusability

If someone wants to build a similar project from scratch (their own APIM + AI Foundry gateway), Spec-Kit can:

- Encode architecture decisions and conventions into **specs and a constitution**
- Guide an AI agent step-by-step through creating the Bicep, notebook, and demo artifacts
- Ensure consistency — anyone following the specs gets a similar, quality baseline

### What it does not cover

Spec-Kit is not a scaffolding or template distribution tool. It does not package artifacts into a starter kit, provide a `create-from-template` command, or handle deployment orchestration.

### Combining approaches for full reusability

| Layer | Tool |
|-------|------|
| **Development process** (how to build it) | Spec-Kit |
| **Template distribution** (clone and customize) | GitHub Template Repo, `azd init`, or Cookiecutter |
| **Deployment orchestration** (run it) | Azure Developer CLI (`azd`), or the runbook in this repo |

## Notebook Setup

Use `runbook.ipynb` for the end-to-end lab flow.

Open it in VS Code:

```bash
$ code runbook.ipynb
```

### Quick start (3 steps)

1. **Run the Step 1 cell** using the default **Python 3** kernel (VS Code will prompt you to choose a kernel the first time — pick **Python 3**). This creates `.venv` and installs dependencies.
2. **Switch to the `.venv` kernel:** click the kernel picker (top-right of the notebook) and select **`.venv (Python 3.12.x)`**.
3. **Run the Step 2 verification cell** to confirm the kernel is active, then continue from Step 3.


## Recommended Architecture

```
Caller (Python SDK / HTTP client)
	Caller (Python SDK / HTTP client)
		│
		▼
	  Azure API Management (Basicv2 tier)
	  ┌──────────────────────────────────────────────────────────┐
	  │  Inference API  /inference/openai/...                    │
	  │  Policy:                                                 │
	  │    • set-backend-service → backend pool                  │
	  │    • retry on 429 / 503 (count=2, tries all backends)    │
	  └───────┬──────────────────────────────────────────────────┘
		  │
		  ▼
	   ┌─────────────────────────────────────────────┐
	   │  Backend Pool (priority + weighted routing) │
	   │                                             │
	   │  ┌─────────────────────────────────────┐   │
	   │  │ Priority 1                          │   │  ← served first
	   │  │ PTU DZ - swedencentral              │   │
	   │  └─────────────────────────────────────┘   │
	   │                                             │
	   │  ┌──────────────────┐ ┌──────────────────┐ │
	   │  │ Priority 2 w=50  │ │ Priority 2 w=50  │ │  ← 50/50 on P1 failover
	   │  │ PayGo DZ         │ │ PayGo DZ         │ │
	   │  │ swedencentral    │ │ germanywestcent  │ │
	   │  └──────────────────┘ └──────────────────┘ │
	   │                                             │
	   │  ┌─────────────────────────────────────┐   │
	   │  │ Priority 3                          │   │  ← last resort
	   │  │ PayGo Global Germany West           │   │
	   │  └─────────────────────────────────────┘   │
	   └─────────────────────────────────────────────┘
```

## Demo Architecture

```
Caller (Python SDK / HTTP client)
	Caller (Python SDK / HTTP client)
		│
		▼
	  Azure API Management (Basicv2 tier)
	  ┌──────────────────────────────────────────────────────────┐
	  │  Inference API  /inference/openai/...                    │
	  │  Policy:                                                 │
	  │    • set-backend-service → backend pool                  │
	  │    • retry on 429 / 503 (count=2, tries all backends)    │
	  └───────┬──────────────────────────────────────────────────┘
		  │
		  ▼
	   ┌─────────────────────────────────────────────┐
	   │  Backend Pool (priority + weighted routing) │
	   │                                             │
	   │  ┌─────────────────────────────────────┐   │
	   │  │ Priority 1                          │   │  ← served first
	   │  │ PTU DZ - swedencentral              │   │
	   │  └─────────────────────────────────────┘   │
	   │                                             │
	   │  ┌──────────────────┐ ┌──────────────────┐ │
	   │  │ Priority 2 w=50  │ │ Priority 2 w=50  │ │  ← 50/50 on P1 failover
	   │  │ PayGo DZ         │ │ PayGo DZ         │ │
	   │  │ swedencentral    │ │ germanywestcent  │ │
	   │  └──────────────────┘ └──────────────────┘ │
	   │                                             │
	   │  ┌─────────────────────────────────────┐   │
	   │  │ Priority 3                          │   │  ← last resort
	   │  │ PayGo Global Germany West           │   │
	   │  └─────────────────────────────────────┘   │
	   └─────────────────────────────────────────────┘
```


### APIM Tiers

Azure API Management is available across several tiers — **Developer**, **Basic**, **Basicv2**, **Standard**, **Standardv2**, **Premium**, and **Consumption** — each offering a different balance of features, scalability, and cost. The classic tiers (Developer through Premium) provide a full-featured gateway with VNet integration, multi-region deployments, and built-in cache, while the v2 tiers (Basicv2, Standardv2) are a modernized offering with faster provisioning and scaling. The Consumption tier is fully serverless and billed per call, making it ideal for low-traffic or dev/test scenarios. Higher tiers unlock advanced capabilities such as availability zones, custom domains per gateway, and dedicated capacity.

For a full feature comparison, see the [Azure API Management tier features](https://learn.microsoft.com/en-us/azure/api-management/api-management-features) documentation.

### Foundry Model Offerings 

Deployment types in Azure AI Foundry define how and where your model's compute capacity is allocated:

![Foundry Models](images/FoundryModels.png)

### Table 

| Deployment type | SKU code | Data processing | Billing | Best for |
|-----------------|----------|-----------------|---------|----------|
| Standard - (PAYGO) Global | GlobalStandard | Any Azure region | Pay-per-token | General workloads, highest quota |
| Standard - (PAYGO) Data Zone | DataZoneStandard | Within data zone | Pay-per-token | EU/US data zone compliance |
| Standard - (PAYGO) Regional  | Standard | Single region | Pay-per-token | Regional compliance, low volume |
| Provisioned Global  | GlobalProvisionedManaged | Any Azure region | Reserved PTU | Predictable high-throughput |
| Provisioned Data Zone  | DataZoneProvisionedManaged | Within data zone | Reserved PTU | Data zone + predictable throughput |
| Provisioned  Regional | ProvisionedManaged | Single region | Reserved PTU | Regional compliance + throughput |
|Batch Global  | GlobalBatch | Any Azure region | 50% discount, 24-hr | Large async jobs |
| Batch Data Zone  | DataZoneBatch | Within data zone | 50% discount | Large async jobs with data zone |
| Developer | DeveloperTier | Any Azure region | Pay-per-token | Fine-tuned model evaluation only |


For more details, see the [Azure AI Foundry deployment types](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types) documentation.


In this demo, all four foundry accounts (`foundry1`–`foundry4`) deploy `gpt-4o-mini` using **`GlobalStandard`** with **8K TPM** capacity each. Combined effective capacity across all four backends = up to **32K TPM** before any 429 Errors surface to the caller — APIM exhausts all backends before returning an error.



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

## Kernel Troubleshooting

If `.venv (Python 3.12.x)` doesn't appear in the kernel picker:

1. Reload VS Code: `Ctrl+Shift+P` → **Developer: Reload Window**
2. Check the kernel picker again — look under *Python Environments*.

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

> The `<13-char hash>` is a deterministic `uniqueString()` derived from the subscription and resource group IDs — it is fixed per deployment and does not vary with `deployment_name`.
