---
name: git-commit
description: >
  Create git commits with conventional commit message analysis, safe staging, and logical grouping.
  Trigger: when the user asks to commit changes, create a git commit, or mentions /commit.
license: MIT
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Git Commit Workflow

## When to Use

Use when the user explicitly asks to create a git commit.

## Safety Rules

- Never commit without the user's explicit request.
- Never commit secrets, `.env`, credentials, private keys, tokens, or generated sensitive files.
- Never update git config unless the user explicitly asks.
- Never run destructive git commands (`reset --hard`, `clean -fd`, force push) without explicit approval.
- Never skip hooks (`--no-verify`) unless the user explicitly asks.
- Never commit directly on protected branches unless the repo intentionally allows it and the user confirms.
- If hooks fail, fix the issue and create a new commit attempt; do not amend unless requested.

## Conventional Commit Format

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

## Workflow

1. Inspect status and branch:
   ```bash
   git status --short --branch
   ```
2. Inspect staged diff first; if nothing is staged, inspect working tree diff:
   ```bash
   git diff --staged
   git diff
   ```
3. Group files into one logical change. Stage only relevant files:
   ```bash
   git add path/to/file1 path/to/file2
   ```
4. Generate a conventional commit message from the actual diff.
5. Run a minimal verification gate if not already done.
6. Commit:
   ```bash
   git commit -m "<type>(<scope>): <description>"
   ```

## Message Rules

- Present tense / imperative mood: `add`, `fix`, `update`.
- Keep the subject under ~72 characters.
- Use a body when the why/tradeoff matters.
- Use `BREAKING CHANGE:` footer or `!` for breaking changes.
- Reference issues when useful: `Refs #123`, `Closes #123`.
