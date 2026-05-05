---
name: zenticalab-pr-review
description: >
  Comprehensive PR review skill for ZENTICALAB projects (.NET backend + Angular frontend).
  Use when reviewing pull requests, checking code quality, or validating implementations against spec.
  Loaded automatically when reviewing PRs in ZENTICALAB repos.
metadata:
  author: lucy-camilo
  version: "1.0"
  project: ZENTICALAB
---

# ZENTICALAB — PR Review Skill

## Project Context

**What ZENTICALAB is:** SaaS multi-tenant B2B for dental labs. Each tenant = a dental lab with its own PostgreSQL schema.

**Stack:**
- Backend: .NET 10, Clean Architecture, EF Core 10, PostgreSQL (schema-per-tenant), FluentValidation, JWT
- Frontend: Angular 21, standalone components, signals, Tailwind CSS 4, Angular SSR
- Testing: xUnit + Moq + Testcontainers (BE), Vitest + axe-core (FE)

**Code language:** English (variables, classes, methods, seeding — all in English)
**UI language:** Colombian Spanish (neutral, no Argentine expressions)

---

## Review Workflow

### 1. Understand the PR

Before reviewing code:
- Read the PR title and description
- Check which files changed
- Identify the feature/fix scope
- Link back to spec.md or relevant HU

### 2. Verify Spec Compliance

- Does the implementation match the spec?
- Are all acceptance criteria addressed?
- Are edge cases handled?
- Is the feature boundary correct (out of scope items not included)?

### 3. Security Checklist

**Backend:**
- [ ] Auth/authz on all endpoints (`[Authorize]`, `[RequirePermissions]`)
- [ ] Input validation via FluentValidation (NOT data annotations)
- [ ] No hardcoded secrets or credentials
- [ ] Multi-tenancy isolation respected (schema-per-tenant)
- [ ] SQL injection prevention (parameterized queries via EF Core)
- [ ] File uploads: content type and size validation
- [ ] JWT validation: signature, expiry, issuer, audience

**Frontend:**
- [ ] No sensitive data in localStorage/sessionStorage without encryption
- [ ] Auth token stored securely (httpOnly cookies preferred over localStorage)
- [ ] XSS prevention: no `innerHTML` with user content, use Angular's sanitization
- [ ] API errors handled gracefully with user feedback

### 4. Architecture Checklist

**Backend:**
- [ ] Clean Architecture: Web.Api → Application → Domain ← Infrastructure
- [ ] Dependencies point inward only
- [ ] Services implement interfaces (no tight coupling)
- [ ] No business logic in controllers
- [ ] Result pattern used (no exceptions for expected flows)
- [ ] Domain entities are POCOs (no framework dependencies)
- [ ] EF Core: no raw SQL unless absolutely necessary (and validated)

**Frontend:**
- [ ] Standalone components (no NgModules unless justified)
- [ ] Signals for state (`signal()`, `computed()`)
- [ ] `ChangeDetectionStrategy.OnPush` on all components
- [ ] Control flow: `@if`, `@for`, `@switch` (no `*ngIf`, `*ngFor`)
- [ ] No `.subscribe()` for pure UI updates (use `toSignal()`)
- [ ] Path aliases used: `@shared/*`, `@core/*`

### 5. Testing Checklist

**Backend:**
- [ ] Unit tests for service layer
- [ ] Unit tests for validators
- [ ] Integration tests for multi-tenant flows
- [ ] Architecture tests for Clean Architecture enforcement
- [ ] Test coverage ≥ 80% on core services

**Frontend:**
- [ ] Spec files colocalized with components
- [ ] Accessibility tests with axe-core
- [ ] Component tests with Vitest

### 6. Design System Compliance (Frontend)

- [ ] Tailwind v4 classes used (no inline styles, no `*ngStyle`)
- [ ] Colors from teal/cyan palette
- [ ] Dark mode supported where applicable
- [ ] Responsive design follows spec breakpoints
- [ ] WCAG AA contrast ratios respected
- [ ] Focus states visible and accessible

### 7. Code Quality Checklist

- [ ] No commented-out code
- [ ] No `TODO`, `FIXME`, or `HACK` left in production code
- [ ] Meaningful variable/method names
- [ ] Methods do one thing (single responsibility)
- [ ] No magic numbers or strings (extract to constants)
- [ ] Error messages are user-friendly (in Colombian Spanish for UI)
- [ ] Logging appropriate (no sensitive data logged)
- [ ] Conventional commits followed: `feat/`, `fix/`, `chore/`, `refactor/`, `test/`

### 8. Performance Checklist

- [ ] No N+1 queries (use eager loading or projections)
- [ ] Large collections paginated
- [ ] Images lazy-loaded where appropriate
- [ ] Bundle size checked (Angular build budgets respected)

---

## Multi-Tenancy Specific

When reviewing tenant-scoped code:
- [ ] All queries use tenant schema (no cross-tenant data leaks)
- [ ] `TenantHttpContext` properly set before any tenant operation
- [ ] Schema migrations are idempotent (`IF NOT EXISTS`)
- [ ] No tenant ID hardcoded — always resolved from context

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

## Key Files to Reference

| File | What it contains |
|------|------------------|
| `docs/spec.md` | Complete product specification |
| `docs/design-system.md` | UI/UX guidelines, colors, components |
| `docs/_sql-conventions.md` | SQL conventions for multi-tenant DB |
| `src/Application/Validators/` | FluentValidation validators |
| `src/Web.Api/Middleware/` | Auth middleware pipeline |
| `src/app/features/*/README.md` | Feature-specific notes |

---

## Anti-Patterns to Flag

| Anti-pattern | What to do instead |
|--------------|-------------------|
| `[Authorize]` without role | Use `[RequirePermissions("Jobs.Create")]` |
| Raw SQL with concatenation | Use EF Core LINQ or parameterized queries |
| `*ngIf` in templates | Use `@if` control flow |
| `.subscribe()` in components for UI | Use `toSignal()` |
| Magic numbers | Extract to named constant |
| `public` fields in entities | Use properties with private setters |
| Business logic in controllers | Extract to service layer |
| Inline styles | Use Tailwind utility classes |
| `innerHTML` with user content | Use Angular sanitization or `[innerHTML]` avoided |
