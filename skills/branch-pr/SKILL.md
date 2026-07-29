---
name: branch-pr
description: >
  Prepare branch state and open pull requests with consistent review metadata.
  Trigger: when a user asks to create a PR, prepare a branch for review, or check PR readiness.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# Branch PR Workflow

## When to Use

Use when changes are ready for collaborative review through a pull request.

Combine with:
- `github-pr` when creating GitHub PR descriptions
- `pr-review` when reviewing PR quality
- `sdd` for all code-change phase gates

## Rules

- Validate branch status and divergence from base first.
- Never push or merge directly to `main`, `master`, or `develop`.
- Do not push, create, update, approve, merge, close, or abandon PRs unless the user explicitly asks for that external action.
- Summarize all branch commits, not only the latest commit.
- Run the smallest meaningful verification gate before claiming readiness.
- Use deterministic PR title/body structure.
- Return PR URL and highlight open risks.

## Checklist

- [ ] Current branch is not protected (`main`, `master`, `develop`).
- [ ] Working tree is clean or intentional changes are explained.
- [ ] Branch is up to date with the intended base or divergence is explained.
- [ ] Commits are logical and reviewable.
- [ ] Tests/build/lint/typecheck were run or a blocker is named.
- [ ] PR body includes summary, validation, risk, and linked issue/spec.
