---
name: security
description: >
  Project-agnostic application security review guidance based on OWASP risks and secure engineering practices.
  Use when reviewing security-sensitive changes, APIs, authentication, authorization, data handling,
  secrets, dependencies, frontend security, infrastructure configuration, or PR security posture.
license: Apache-2.0
metadata:
  author: lucy-camilo
  version: "1.1"
---

# Application Security Review Skill

## When to Use

Use this skill when:
- Reviewing PRs for security risk
- Designing or changing auth/authz, identity, permissions, sessions, tokens, or tenant boundaries
- Handling sensitive data, files, payments, PII, credentials, or audit logs
- Adding dependencies, CI/CD steps, infrastructure config, or public endpoints
- Investigating vulnerabilities or hardening an app

Always combine this with:
- The repo's `docs/STANDARDS.md`
- The applicable stack skill, such as `csharp-dotnet`, `angular-core`, or `typescript`
- Project-specific threat model or compliance docs if present

## Golden Rule

> Security is not an optional feature. If a change can expose data, escalate privileges, weaken auth, bypass validation, leak secrets, or break auditability, treat it as blocking until proven safe.

## Security Review Workflow

1. Identify assets: user data, tenant data, secrets, payments, files, admin actions, logs, tokens.
2. Identify trust boundaries: browser/server, public/private network, tenant/user/admin, third-party APIs, queues, background jobs.
3. Check the changed code against the checklist below.
4. Look for negative tests: unauthorized, forbidden, invalid input, expired token, wrong tenant/user, malformed file, replay, race.
5. Classify findings as blocking/suggestion/nit and cite exact files/lines.

## Core Checklist

### Access Control

- [ ] Server enforces authorization; UI checks are only convenience.
- [ ] Every protected endpoint/action has explicit permission/role/policy checks.
- [ ] Object-level authorization prevents IDOR/BOLA: users can only access resources they own or are allowed to manage.
- [ ] Tenant/account/project boundaries cannot be selected from untrusted URL/query/body values unless verified.
- [ ] Admin and support flows require stronger checks and audit logs.
- [ ] Default behavior is deny, not allow.

**Flag immediately:** client-only permission checks, predictable IDs without ownership checks, wildcard admin access, missing policy on write/delete/export endpoints.

### Authentication and Session Security

- [ ] Passwords are hashed with approved password hashing algorithms; never custom crypto.
- [ ] JWT/session validation checks issuer, audience, signature, expiry, and revocation/session state where required.
- [ ] Refresh tokens are rotated and stored safely.
- [ ] Cookies use `HttpOnly`, `Secure`, and appropriate `SameSite`.
- [ ] MFA/step-up auth is considered for high-risk actions.
- [ ] Login, reset, invitation, and email-change flows avoid account enumeration.

### Input Validation and Injection

- [ ] All untrusted input is validated at the server boundary.
- [ ] SQL/NoSQL/LDAP queries use parameterization or safe ORM APIs.
- [ ] Shell commands avoid user-controlled strings; if unavoidable, use argument arrays and allowlists.
- [ ] HTML/Markdown rendering is sanitized.
- [ ] File paths are normalized and restricted to expected directories.
- [ ] Regexes avoid catastrophic backtracking on untrusted input.

### Cryptography and Secrets

- [ ] No secrets, tokens, private keys, connection strings, or API keys are committed.
- [ ] Secrets come from environment variables, secret managers, or managed identity.
- [ ] TLS is required for sensitive traffic.
- [ ] Encryption uses vetted libraries and safe modes; no custom algorithms.
- [ ] Keys have rotation strategy and are not logged.
- [ ] Sensitive data at rest is encrypted when required by risk/compliance.

### Security Misconfiguration

- [ ] Production disables debug pages, verbose errors, test endpoints, and permissive logging.
- [ ] CORS uses explicit origins, not `*` with credentials.
- [ ] Security headers are configured where applicable: CSP, HSTS, X-Content-Type-Options, Referrer-Policy, frame protections.
- [ ] Cloud resources are private by default and least-privilege.
- [ ] Health/status endpoints do not leak versions, env vars, dependency details, or secrets.

### Dependency and Supply Chain

- [ ] Dependency changes are reviewed intentionally, including transitive risk.
- [ ] Lockfiles are committed and reviewed.
- [ ] CI runs vulnerability scanning appropriate to the stack.
- [ ] Build scripts do not curl/bash unverified remote code.
- [ ] Package sources/registries are trusted and pinned where possible.
- [ ] GitHub Actions or CI workflows pin third-party actions by SHA for high-security repos.

### Data Protection and Privacy

- [ ] Responses expose only required fields.
- [ ] Logs/telemetry do not include secrets, tokens, passwords, PII, payment data, or sensitive payloads.
- [ ] Data export/download endpoints enforce authorization, rate limits, and audit logging.
- [ ] Deletion/anonymization follows product/compliance requirements.
- [ ] Backups, caches, queues, and search indexes respect data retention and isolation rules.

### File Uploads and Downloads

- [ ] File size, type, extension, MIME, and content are validated.
- [ ] Uploaded files are scanned or sandboxed when risk justifies it.
- [ ] Files are stored outside executable web roots or served through controlled download handlers.
- [ ] Download paths cannot be traversed with `../` or encoded variants.
- [ ] User-provided filenames are sanitized before storage/display.

### Frontend Security

- [ ] No sensitive tokens or secrets are stored in localStorage/sessionStorage unless explicitly accepted by the threat model.
- [ ] XSS risks are controlled: avoid unsafe HTML, sanitize rich text, do not bypass framework sanitizers.
- [ ] CSP/Trusted Types are considered for high-risk apps.
- [ ] Client-side feature flags or hidden controls are not treated as authorization.
- [ ] Error messages do not reveal sensitive internals.

### APIs and Integrations

- [ ] Public APIs have authentication, authorization, validation, rate limits, and auditability where needed.
- [ ] Webhooks verify signatures and timestamps and are replay-resistant.
- [ ] Outbound calls use allowlisted hosts when possible and avoid SSRF.
- [ ] Third-party API failures are handled safely without leaking secrets or corrupting state.
- [ ] Idempotency keys protect retryable write operations.

## Severity Guide

| Severity | Examples | Action |
|---|---|---|
| 🔴 Blocking | Auth bypass, tenant/user data leak, injection, secrets committed, unsafe file handling, production debug exposure, missing required security tests | Request changes |
| ⚠️ Important | Weak logging/auditing, missing rate limits, incomplete validation, dependency risk needing follow-up | Suggest fix or create tracked task |
| 💬 Advisory | Defense-in-depth improvement, documentation gap, minor hardening | Non-blocking note |

## Secure Review Comment Pattern

Use this format for findings:

```markdown
🔴 Blocking — [short title]
File: `path/to/file.ext:line`

What I found:
[Specific behavior]

Why it matters:
[Security impact]

Suggested fix:
[Concrete change]

Expected test:
[Negative/positive test that proves it]
```

## Common Anti-Patterns

| Anti-pattern | Safer approach |
|---|---|
| Client-only auth checks | Server-side authorization policy/object ownership checks |
| `AllowAnyOrigin()` with credentials | Explicit CORS origin allowlist |
| Raw string SQL/commands | Parameterized queries / safe argument APIs |
| Secrets in app config committed to repo | Secret manager/env vars/managed identity |
| Logging full request/response bodies | Structured logs with redaction |
| Trusting tenant/account IDs from request body | Resolve from authenticated context, then verify ownership |
| Serving uploaded files directly | Controlled download endpoint with authorization and safe content headers |
| Disabling TLS validation | Fix certificates/trust store |
| Broad cloud IAM roles | Least-privilege scoped identities |

## Useful Commands

Run only commands appropriate for the repo's stack:

```bash
# .NET
dotnet list package --vulnerable --include-transitive
dotnet list package --outdated

# Node/npm
npm audit --audit-level=high
npm outdated

# Git secret scan examples, if tools are installed
gitleaks detect --source .
trufflehog filesystem .
```

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Microsoft Security Development Lifecycle](https://www.microsoft.com/en-us/securityengineering/sdl)
