---
name: azure-sign-in
description: >
  Sign in to Azure with CLI using interactive login. Trigger: when Azure CLI or Azure
  DevOps CLI authentication is required and the user has approved interactive sign-in.
license: Apache-2.0
context: fork
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Azure CLI - Sign In

## OpenClaw Safety Rules

- Prefer read-only/list/show commands first.
- Do not run destructive Azure DevOps commands (`delete`, `destroy`, disabling policies, removing permissions, deleting branches/repos/projects/service endpoints) without explicit user approval.
- Do not complete, merge, approve, or abandon PRs unless the user explicitly asks for that external action.
- Do not install Azure CLI/extensions with `curl | sudo bash` automatically; ask the user or use an approved package manager path.
- Never ask the user to paste PATs/secrets into chat. Prefer existing auth, managed identity, browser/device login, or environment variables configured outside the repo.
- Do not echo tokens, secrets, connection strings, or credentials into shell history, logs, files, PR comments, or work items.
- For external writes to Azure DevOps, summarize the exact target org/project/repo/work item and intended mutation before acting.

This skill allows you to sign in to Azure using the Azure CLI. You can use this skill to authenticate your CLI session and access Azure resources.


**CLI Version:** 2.85.0 (current as of May 2026)


## Prerequisites

Install Azure CLI and Azure DevOps extension:

```bash
# Install Azure CLI
brew install azure-cli  # macOS
# Linux install requires user approval; do not run curl|sudo automatically
pip install azure-cli  # via pip

# Verify installation
az --version

# Install Azure DevOps extension
az extension add --name azure-devops
az extension show --name azure-devops
```

## Interactive Login
To sign in to Azure interactively, run the following command:

```bash
az login
```
If user has multiple accounts, they will be prompted to select the account they want to use. Pressing `Enter` will select the default account.
