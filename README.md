# from-specs-to-mission-critical-deployments
How to use Github spec-kit to build an AI App that'll use multiple MS Foundry Models behind Azure AI Gateway

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

## Kernel Troubleshooting

If `.venv (Python 3.12.x)` doesn't appear in the kernel picker:

1. Reload VS Code: `Ctrl+Shift+P` → **Developer: Reload Window**
2. Check the kernel picker again — look under *Python Environments*.
