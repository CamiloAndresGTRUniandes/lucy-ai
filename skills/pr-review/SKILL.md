---
name: pr-review
description: >
  Comprehensive, project-agnostic pull request review workflow.
  Use when reviewing PRs, checking code quality, validating implementations against specs,
  or deciding whether to approve, request changes, or ask for discussion.
license: Apache-2.0
metadata:
  author: lucy-camilo
  version: "1.1"
---

# PR Review Skill

## When to Use

Use this skill when:
- Reviewing a pull request or branch diff
- Validating implementation against a spec, issue, task, or acceptance criteria
- Checking whether code is safe, maintainable, tested, and ready to merge
- Preparing a GitHub/GitLab/Bitbucket PR review comment

Before reviewing project-specific code, read the repo's local standards first, usually:
- `docs/STANDARDS.md`
- `docs/spec.md`, `spec.md`, or feature-specific specs if present
- Any contribution/review guide in the repo

Then load the relevant technology skills only when they apply, for example TypeScript, Angular, .NET, Tailwind, or security skills.

## Review Principles

- Be evidence-based: cite exact files/lines where possible.
- Separate blockers from suggestions.
- Prefer fewer, sharper comments over noisy review spam.
- Judge the implementation against the agreed spec, not personal taste.
- Flag security, data loss, privacy, auth/authz, migration, and compatibility risks aggressively.
- Do not approve if tests are missing for important behavior.
- Do not request changes for subjective style unless it violates documented standards or creates maintainability risk.

## Review Workflow

### 1. Understand the PR

- Read the PR title and description.
- Identify the intended scope: feature, bugfix, refactor, chore, security fix, migration, or dependency update.
- Inspect changed files and affected boundaries.
- Find the source of truth: issue, spec, acceptance criteria, design doc, or task list.
- Note out-of-scope changes that increase review risk.

### 2. Verify Spec Compliance

- Does the implementation satisfy all acceptance criteria?
- Are edge cases covered?
- Are error states handled?
- Is the feature boundary respected?
- Are user-visible behaviors, API contracts, schemas, and permissions consistent with the spec?

### 3. Security Checklist

- [ ] Authentication and authorization are enforced where needed.
- [ ] Access control is checked server-side, not only in UI/client code.
- [ ] User input is validated and encoded/sanitized appropriately.
- [ ] Database/file/command queries avoid injection risks.
- [ ] Secrets, tokens, credentials, and private keys are not committed or logged.
- [ ] Sensitive data is not exposed in responses, logs, telemetry, URLs, or client storage.
- [ ] File uploads/downloads validate type, size, path, permissions, and content handling.
- [ ] Cryptography uses approved libraries and safe defaults; no custom crypto.
- [ ] Rate limits, abuse controls, and audit logging are considered for sensitive actions.

### 4. Architecture Checklist

- [ ] Changes fit the existing architecture and dependency direction.
- [ ] Business rules are in the appropriate layer/module.
- [ ] Public APIs/contracts are versioned or backward-compatible when required.
- [ ] The implementation is cohesive and avoids unnecessary coupling.
- [ ] Error handling is explicit and consistent with project conventions.
- [ ] Data model changes include migration/rollback implications.
- [ ] Cross-cutting concerns such as logging, tracing, validation, caching, and authorization are handled consistently.

### 5. Testing Checklist

- [ ] Unit tests cover important branches and failure modes.
- [ ] Integration/API/component tests cover critical workflows where useful.
- [ ] Regression tests exist for bug fixes.
- [ ] Security-sensitive paths include negative tests.
- [ ] Tests are deterministic and do not depend on hidden local state.
- [ ] Test names describe behavior, not implementation details.
- [ ] Existing tests/build/lint/typecheck pass or failures are explained.

### 6. Code Quality Checklist

- [ ] Code is readable and idiomatic for the project.
- [ ] Names communicate intent.
- [ ] Functions/classes/components have clear responsibilities.
- [ ] No dead code, commented-out code, debug prints, or accidental TODO/FIXME/HACK comments.
- [ ] Duplication is intentional or small enough not to matter.
- [ ] Constants/configuration replace magic values where meaning matters.
- [ ] Logs are useful and do not leak sensitive data.
- [ ] Dependencies are justified and do not introduce avoidable risk.

### 7. Performance and Reliability Checklist

- [ ] No obvious N+1 queries, unbounded loops, or unnecessary network calls.
- [ ] Large lists/results are paginated, streamed, capped, or lazy-loaded.
- [ ] Expensive work is cached, batched, or moved off the hot path when appropriate.
- [ ] Timeouts, retries, cancellation, and idempotency are considered for external calls.
- [ ] Concurrency/race conditions are considered for shared state and writes.
- [ ] Observability is adequate for diagnosing production issues.

### 8. UX / API Contract Checklist

- [ ] User-facing errors are clear and actionable.
- [ ] Loading, empty, disabled, and failure states are handled.
- [ ] Accessibility is considered for UI changes.
- [ ] API responses and status codes are consistent.
- [ ] Breaking changes are documented and coordinated.

## Severity Guide

| Severity | Use for | Review action |
|---|---|---|
| 🔴 Blocking | Security risk, data loss, broken spec, failing critical path, missing required tests, breaking API/migration risk | Request changes |
| ⚠️ Suggestion | Maintainability, performance, readability, missing non-critical edge case | Comment, usually non-blocking |
| 💬 Nit | Small style/readability issue with low impact | Avoid unless project expects detailed nits |
| ✅ Praise | Good design, clear tests, thoughtful handling | Mention briefly when useful |

## Review Output Format

When posting a PR review, use this structure:

```markdown
## PR Review: [PR Title]

### Summary
[1-3 sentences on what this PR changes and overall readiness]

### ✅ Looks Good
- [specific strength]

### 🔴 Blocking Issues
- [file:line — issue, why it matters, suggested fix]

### ⚠️ Suggestions
- [file:line — improvement, tradeoff, optionality]

### Security
- [Passed / Issues found / Not applicable] — [brief note]

### Testing
- [Adequate / Missing / Not run] — [brief note]

### Recommendation
**Approve** / **Request Changes** / **Needs Discussion**
```

If there are no blocking issues, write `None found` under Blocking Issues. If tests were not run, say exactly why.

## Anti-Patterns to Flag

| Anti-pattern | Why it matters |
|---|---|
| Client-only authorization | Users can bypass UI controls |
| Unvalidated input | Injection, crashes, inconsistent state |
| Raw dynamic queries/commands | Injection and escaping risk |
| Secrets in code/config committed to repo | Credential compromise |
| Logging sensitive data | Privacy/security breach |
| Silent error swallowing | Production issues become undiagnosable |
| Business logic in transport/UI layer | Harder to test and maintain |
| Large unrelated refactors inside feature PRs | Review risk and regression surface increase |
| Missing tests for new behavior | Regressions become likely |
| Non-idempotent migrations or jobs | Retry/deploy failures can corrupt state |
