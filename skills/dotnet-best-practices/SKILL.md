---
name: dotnet-best-practices
description: >
  Project-agnostic .NET/C# best-practices review for structure, DI, async, configuration,
  logging, errors, testing, security, and maintainability. Trigger: when broadly reviewing .NET code quality.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# .NET/C# Best Practices Review

## When to Use

Use for broad .NET code-quality review. Combine with `csharp-dotnet`, `csharp-async`, `csharp-xunit`, `security`, and project `docs/STANDARDS.md` as applicable.

## Review Areas

- Architecture follows repo standards and keeps responsibilities separated.
- Dependency injection uses appropriate lifetimes and avoids captive dependencies.
- Public APIs and shared abstractions are documented when useful.
- Async I/O uses async/await, cancellation tokens, and avoids blocking.
- Configuration is strongly typed and validated at startup for critical settings.
- Logging is structured and avoids sensitive data.
- Error handling uses project conventions consistently.
- Database access uses parameterization and avoids N+1 queries.
- Tests cover meaningful behavior and failure paths.
- Security-sensitive paths validate input, authz, and data exposure.

## Avoid Over-Prescription

Do not force a pattern/framework because this skill mentions it. Repo standards and existing architecture win. Suggest changes only when they improve correctness, maintainability, security, or testability.
