# TOOLS.md - Your Workspace

> Last updated: 2026-04-29

---

## General Notes (cross-project)

Skills define _how_ tools work. This file is for _your_ specifics — things unique to your setup, shared across all projects.

### OpenClaw Session

- **Thinking level**: `high` — OBLIGATORIO para TODOS los cambios de código, arquitectura y decisiones técnicas. Solo bajar a `low` o `off` cuando sea solo conversación casual.
- Can be set per-session from the dashboard/web UI (chat settings). Currently: high.

### What goes here

- SSH hosts and aliases
- Camera names and locations
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Environment-specific config
- Any personal cheat sheet useful across projects

### Examples

```markdown
### SSH
- home-server → 192.168.1.100, user: admin

### TTS
- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod

### Git
- Always use --signed-off on commits (SOPS)
- Default branch: main
```

---

## ZENTICALAB Project Standards

> Dental Lab Management SaaS — .NET 10 backend, Angular 21 frontend, PostgreSQL schema-per-tenant

### Project Identity
- **Stack**: .NET 10 backend (Clean Architecture), Angular 21 frontend (standalone + signals), PostgreSQL schema-per-tenant, Azure Blob / Azurite
- **Language**: English (code, variables, seeding, comments)
- **UI language**: Colombian Spanish (neutral, no Argentine expressions)
- **Location**: `/home/node/.openclaw/workspace/ZENTICALAB/`
- **Backend repo**: `CamiloAndresGTRUniandes/BE_ZENTICALAB`
- **Frontend repo**: `CamiloAndresGTRUniandes/FE_ZENTICALAB`
- **GitHub user**: `lucygtr` | **Reviewer**: `camiloandresgtruniandes`
- **Local repos**: `/workspace/repos/ZENTICALAB/backend/` y `/workspace/repos/ZENTICALAB/frontend/`

### Architecture Principles

**Clean Architecture** (enforced with NetArchTest.Rules)
```
Web.Api → Application → Domain ← Infrastructure ← SharedKernel
```
- **Domain layer**: entities, value objects, enums — NO dependencies
- **Application layer**: DTOs, interfaces, services, validators — depends only on Domain
- **Infrastructure layer**: implementations, SQL queries, external services
- **Web.Api layer**: controllers, middleware, DI registration

**SOLID** — Strictly enforced
- **S**ingle responsibility: every class/interface has one reason to change
- **O**pen/closed: extend behavior via new types, not modification
- **L**iskov substitution: subtype contracts must be honored
- **I**nterface segregation: small, focused interfaces (no fat interfaces)
- **D**ependency inversion: depend on abstractions, not implementations

**DRY** — Every piece of knowledge has a single representation
- Shared logic → shared module
- Repeated patterns → extracted to helper / mapper / base class
- **Never** copy-paste SQL, markup, or validation rules

**Clean code rules**
- Types/classes/records: PascalCase, noun phrase (`InventoryAlertDto`)
- Methods: PascalCase, verb phrase (`GetAlertSummaryAsync`)
- Local variables: camelCase
- Private nested types: `private sealed record` for SQL row types
- No abbreviations unless universally understood
- No magic numbers — extract to named constants

### Backend Standards

**Location**: `/home/node/.openclaw/workspace/ZENTICALAB/backend/`

**DTOs**
- **Located**: `src/Application/DTOs/Tenant/`
- **Format**: `public sealed class` (mutable DTOs with `{ get; set; }`)
- **Naming**: `*Dto`, `*RequestDto`, `*ResultDto`, `*QueryDto`
- **Validation**: FluentValidation only — NO data annotation attributes on DTOs
- **Records**: use `public record` only for truly immutable result types

**Services**
- **Interface**: `I*Service` in `Application/Interfaces/Services/`
- **Implementation**: `*Service` in `Infrastructure/Services/Tenant/`
- **Row types** (SQL mappings): `private sealed record *Row(...)` — NOT in the service class
- **Mappers**: extracted to `Mappers/` subfolder under the service directory
- **DI**: Scoped, registered in `Program.cs`

**SQL Query Patterns**
- Always use `SqlQueryRaw<T>` with interpolated parameters for tenant-isolated queries
- Always use `TenantSqlBuilder.ValidateSchema()` before any SQL
- Never concatenate schema names or table names directly
- Raw SQL rows: private nested records or extracted to Mappers

**Controller Patterns**
- `[Authorize(Roles = "...", "...", ...)]` at class level
- `[RequirePermissions("...")]` at action level — **always required** (not optional)
- Use `TenantHttpContext.GetTenantRequestContext()` to extract tenant context
- Return `Forbid()` when context is null
- Return `Ok(result)` for success — no wrapping in additional envelopes

**Tests**
- **Unit**: `tests/BE_ZENTICALAB.UnitTests/` — Moq, xUnit
- **Integration**: `tests/BE_ZENTICALAB.IntegrationTests/` — Testcontainers + real DB
- **Coverage target**: > 80% service layer

### Frontend Standards

**Location**: `/home/node/.openclaw/workspace/ZENTICALAB/frontend/`

**Architecture**
- Angular 21 **standalone components** only — NO NgModules
- Signal-based state management — `signal()`, `computed()`
- `ChangeDetectionStrategy.OnPush` on all components — mandatory
- No `NgZone.run()` unless absolutely necessary
- Lazy-loaded routes via `loadComponent`

**Component Structure**
```
features/tenant/[feature]/
  [feature].model.ts          ← interfaces, types, constants
  [feature].service.ts        ← @Injectable({ providedIn: 'root' })
  [feature]-page.component.ts ← page container
  components/
    [component].component.ts  ← reusable, self-contained
  testing/
    [feature].fixture.ts      ← test helpers
```

**Patterns**
- Use `inject()` instead of constructor injection
- Input/output: `input.required()`, `output()` signal-based API
- No `*ngIf`/`*ngFor` — use Angular 17+ `@if`/`@for` control flow
- Never use `ngStyle` — use `[class]` binding with methods or ternary
- Tailwind v4: dark mode via `dark:` prefix classes, no CSS ad-hoc

**Naming**
- Components: `PascalCase.component.ts`
- Services: `PascalCase.service.ts`
- Models: `kebab-case.model.ts`

**Tests**
- Vitest + Angular TestBed
- `beforeEach` setup pattern, clear mock isolation per test

### Commit Convention

Format: `type(HU-n): short description`

Types:
- `feat`: new feature
- `fix`: bug fix
- `refactor`: internal improvement (no behavior change)
- `docs`: documentation only
- `test`: test-only changes

Examples:
```
feat(HU34): add inventory alerts backend
fix(HU34): add RequirePermissions attribute
refactor(HU34): extract row types and mappers out of InventoryAlertService
```

### Git Workflow (strict — never bypass)

**Ramas protegidas — SIN EXCEPCIÓN:**
- `main` y `develop` — **nunca push directo**, siempre via PR con review de `camiloandresgtruniandes`
- Pre-push hooks activos en `/workspace/repos/ZENTICALAB/backend/` y `/workspace/repos/ZENTICALAB/frontend/` que bloquean push a estas ramas
- GitHub Free no permite branch protection — los hooks locales son la primera línea de defensa

1. All work on **feature branches** (`feat/huXX-description`)
2. **Never** push/merge directly to `main` or `develop`
3. Open PR → assign `camiloandresgtruniandes` as reviewer
4. PR requires at minimum one approved review before merge
5. Never force-push protected branches
6. All commits must be signed-off

**Review checklist (before opening PR)**
- [ ] SOLID: each class has single responsibility?
- [ ] DRY: no repeated logic, no copy-paste?
- [ ] Clean Architecture: correct layer placement?
- [ ] Backend: FluentValidation, no data annotations?
- [ ] Backend: `[RequirePermissions]` on all controller actions?
- [ ] Frontend: OnPush on all components?
- [ ] Frontend: standalone components, no NgModules?
- [ ] Tests: unit tests added for new services?
- [ ] No secrets in code (env vars for everything)

### Environment & Secrets

- **Local dev**: `.env` file (git-ignored)
- **Production**: Azure Key Vault path referenced via env var
- **Never commit**: connection strings, JWT keys, passwords, connection credentials
- **Placeholders in appsettings.json**: `${ENV_VAR_NAME}` format (ASP.NET resolves natively)

---

## Related

- [AGENTS.md](/AGENTS.md) — workspace conventions and SDD workflow
- [SOUL.md](/SOUL.md) — persona and tone
- [USER.md](/USER.md) — about Camilo