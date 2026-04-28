---
name: pr-review
description: >
  Generic PR review skill for any software project.
  Use when reviewing pull requests, checking code quality, or validating implementations against spec.
  Applies to all projects — no project-specific conventions included.
  For project-specific conventions, add them to the project's workspace TOOLS.md.
metadata:
  author: lucy-ai
  version: "1.0"
---

# PR Review Skill

Generic, project-agnostic PR review. Project-specific conventions (naming, stack details, design system) should live in the project's own workspace — not here.

---

## Review Workflow

### 1. Understand the PR

Before reviewing code:
- Read the PR title and description
- Check which files changed
- Identify the feature/fix scope
- Link back to spec, issue, or task tracker

### 2. Verify Spec Compliance

- Does the implementation match the spec?
- Are all acceptance criteria addressed?
- Are edge cases handled?
- Is the feature boundary correct (out of scope items not included)?

### 3. Security Checklist

- [ ] Auth/authz on all endpoints (no public-facing unauthenticated endpoints unless explicitly public)
- [ ] Input validation on all user-provided data (whitelist, not blacklist)
- [ ] No hardcoded secrets, credentials, or API keys in code
- [ ] SQL injection prevention (parameterized queries, ORM usage)
- [ ] File uploads: content type and size validation
- [ ] Sensitive data not logged
- [ ] Permissions checked server-side (client-side checks are UX only)

### 4. Architecture Checklist

- [ ] Clean Architecture: dependencies point inward (UI → Business Logic → Data)
- [ ] No business logic in controllers/presenters
- [ ] Services implement interfaces (no tight coupling to implementations)
- [ ] No magic numbers or strings (extract to named constants)
- [ ] Error handling is explicit (no silent failures)
- [ ] External dependencies abstracted behind interfaces

### 5. Testing Checklist

- [ ] Unit tests for business logic
- [ ] Unit tests for validation
- [ ] Integration tests for external integrations (DB, API clients)
- [ ] Test coverage adequate for the complexity (≥80% for core services)
- [ ] No empty/incomplete tests left behind

### 6. Code Quality Checklist

- [ ] No commented-out code left in
- [ ] No `TODO`, `FIXME`, `HACK` in production code
- [ ] Meaningful variable/method names (intent is clear)
- [ ] Methods do one thing (single responsibility)
- [ ] Functions are small (if it's >50 lines, question it)
- [ ] No premature optimization (make it work, then make it fast)
- [ ] Conventional commits followed: `feat/`, `fix/`, `chore/`, `refactor/`, `test/`
- [ ] Error messages are actionable and helpful

### 7. Performance Checklist

- [ ] No N+1 queries or requests
- [ ] Large data sets paginated or lazy-loaded
- [ ] No blocking operations on the main thread/event loop
- [ ] Expensive operations done async where appropriate

---

## Anti-Patterns to Flag

| Anti-pattern | What to do instead |
|--------------|-------------------|
| Magic numbers | Extract to named constant |
| God class/object | Split into smaller, focused units |
| No input validation | Validate all user input, fail fast |
| No error handling | Handle errors explicitly, don't swallow |
| Hardcoded credentials | Use environment variables or secrets manager |
| `console.log` left in | Remove or use proper logging |
| Inconsistent naming | Pick convention and stick to it |
| Premature optimization | Write clear code first, optimize when measured |

---

## Review Output Format

When posting a PR review, use this structure:

```markdown
## PR Review: [PR Title]

### Summary
[1-3 sentences on what this PR does and its quality]

### ✅ Looks Good
- [item that works well]

### ⚠️ Suggestions
- [optional improvement, non-blocking]

### 🔴 Blocking Issues
- [must-fix before merge, with specific file:line references]

### Security
- [ ] Passed / [ ] Issues found

### Testing
- [ ] Tests adequate / [ ] Tests missing

### Recommendation
**Approve** / **Request Changes** / **Needs Discussion**
```

---

## Principles

1. **Be specific** — Reference exact files and line numbers
2. **Explain the why** — Don't just say "bad", say why it's a problem
3. **Distinguish blocking vs. suggestions** — Not everything is a blocker
4. **Acknowledge good work** — Reinforce what's done right
5. **Be kind** — Code is written by humans; critique the code, not the person
