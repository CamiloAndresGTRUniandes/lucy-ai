---
name: dotnet10-csharp14
description: >
  Project-agnostic .NET 10 and C# 14 best practices: field keyword,
  null-conditional assignment, extension members, unbound generic nameof,
  runtime improvements, ASP.NET Core, and EF Core guidance.
  Trigger: When using .NET 10, C# 14, ASP.NET Core 10, EF Core 10, or deciding whether to adopt new language/runtime features.
license: Apache-2.0
metadata:
  author: lucy-camilo
  version: "1.1"
---

# .NET 10 + C# 14 Best Practices

## When to Use

Use this skill when:
- Writing or reviewing .NET 10 / C# 14 code
- Deciding whether to adopt a new C# 14 feature
- Modernizing .NET projects without rewriting stable code unnecessarily
- Reviewing ASP.NET Core 10, EF Core 10, or runtime-related changes

Always combine this with the repo's own `docs/STANDARDS.md` and the generic `csharp-dotnet` skill when broader .NET architecture guidance is needed.

## Adoption Rule

> Use .NET 10 / C# 14 features only when they improve clarity, safety, maintainability, or performance. Do not rewrite working code just to use new syntax.

Before adopting new features, verify:
- [ ] The project targets .NET 10 and LangVersion supports C# 14
- [ ] CI/build images have the .NET 10 SDK installed
- [ ] Team/editor tooling supports the syntax
- [ ] Existing tests still pass
- [ ] The feature fits the project's architecture and style guide

## C# 14 Features Worth Using

### 1. `field` keyword — validated properties without explicit backing field

Use when a property needs simple validation or normalization in the setter.

```csharp
public string Name
{
    get;
    set => field = string.IsNullOrWhiteSpace(value)
        ? throw new ArgumentException("Name is required.", nameof(value))
        : value.Trim();
}
```

Good fits:
- Small invariants on DTOs or domain objects
- Normalization such as trimming strings
- Replacing trivial private backing fields

Avoid when:
- Validation belongs in FluentValidation or another validation layer
- The setter becomes complex
- The class already has a member named `field`; use `@field` or rename to avoid confusion

### 2. Null-conditional assignment — `?.=`

Use when assigning only if the target exists; right-hand side is not evaluated if the receiver is null.

```csharp
currentUser?.LastSeenAt = clock.UtcNow;
```

Good fits:
- Optional state updates
- Defensive assignments in mapping code
- Optional telemetry/log enrichment

Avoid when:
- Null should be treated as an error
- Assignment hides an unexpected missing dependency
- Increment/decrement is needed (`++` / `--` are not supported)

### 3. Extension members — extension properties and static extension methods

Use for tiny, broadly useful helpers where fluent/readable syntax matters.

```csharp
public static class CollectionExtensions
{
    extension<T>(IReadOnlyCollection<T> source)
    {
        public bool IsEmpty => source.Count == 0;
    }
}
```

Good fits:
- Small collection/string/result helpers
- Domain-specific readability improvements
- Avoiding repeated utility boilerplate

Avoid when:
- The extension hides expensive work
- A normal method would be clearer
- It encourages an anemic domain model by moving real behavior out of domain types

### 4. `nameof(List<>)` — unbound generic `nameof`

Use when referring to generic type names without inventing a type argument.

```csharp
var collectionType = nameof(List<>);        // "List"
var mapType = nameof(Dictionary<,>);        // "Dictionary"
```

Good fits:
- Diagnostics and exception messages
- Metadata or validation involving generic type definitions
- Source generators/analyzers

### 5. Partial constructors and partial events

Use to split generated and handwritten code safely.

```csharp
public partial class ReportBuilder
{
    partial void OnBuildFailed(Exception exception);
}
```

Good fits:
- Source generators
- Separating generated code from custom hooks
- Optional telemetry hooks in partial classes

Avoid when:
- It makes object construction harder to understand
- A normal constructor or event is simpler

### 6. Lambda parameter modifiers without explicit types

Use when delegates need `out`, `ref`, or `in` parameters and the type is obvious.

```csharp
TryParse<int> parser = (text, out result) => int.TryParse(text, out result);
```

Good fits:
- Callback-heavy code
- Parsers and low-level helpers

Avoid when:
- Explicit types improve readability
- The delegate signature is not obvious nearby

## .NET 10 Runtime Guidance

### JIT inlining and devirtualization

Small methods and interface calls may perform better without code changes. Prefer clear code first; measure before introducing micro-optimizations.

### NativeAOT improvements

Consider NativeAOT for:
- CLI tools
- Serverless/functions
- Small worker services
- Fast startup / low memory scenarios

Avoid NativeAOT when the app relies heavily on reflection, dynamic loading, or libraries that are not AOT-friendly unless tested carefully.

### Vectorization improvements

Use built-in APIs (`System.Numerics`, spans, memory APIs) before custom SIMD code. Only optimize numerical hot paths after profiling.

## ASP.NET Core 10 Guidance

- Keep validation explicit and consistent with project standards.
- Verify generated OpenAPI schemas for required properties and nullability.
- Preserve secure defaults: HTTPS, auth/authz, CORS restrictions, safe headers, and production-safe error handling.
- Avoid framework-version upgrades without smoke tests for middleware ordering, auth, serialization, and model binding.

## EF Core 10 Guidance

### Named query filters

Use named filters when the project needs independently disabled filters, such as soft-delete plus tenant or region filtering.

```csharp
modelBuilder.Entity<Order>()
    .HasQueryFilter(o => !o.IsDeleted, "SoftDeleteFilter")
    .HasQueryFilter(o => o.TenantId == tenantContext.TenantId, "TenantFilter");
```

Rules:
- Do not disable filters casually; require an explicit use case and tests.
- Keep authorization checks separate from convenience query filters.
- Verify generated SQL for critical queries.

### LINQ translation improvements

Prefer clear LINQ, but inspect generated SQL for complex queries, aggregation, pagination, or string operations.

## Review Checklist

- [ ] New syntax improves the code instead of adding novelty.
- [ ] Behavior is covered by tests.
- [ ] Public API contracts remain compatible or breaking changes are documented.
- [ ] Nullability annotations are correct.
- [ ] Performance claims are backed by profiling or benchmarks.
- [ ] Framework upgrades include build/test/CI updates.
- [ ] EF Core changes include migration and rollback implications.

## Imported Backend Reference Pack

Additional backend-specific .NET 10/C# 14 references were imported under `references/backend-pack/`:

- `overview.md` — quick-start patterns and decision flowcharts
- `csharp-14.md` — extension blocks, `field`, null-conditional assignment
- `minimal-apis.md` — validation, TypedResults, endpoint filters, vertical slices
- `security.md` — JWT, CORS, rate limiting, OpenAPI security, middleware order
- `infrastructure.md` — options, resilience, channels, health checks, caching, Serilog, EF Core
- `testing.md` — WebApplicationFactory, integration tests, auth testing
- `anti-patterns.md` — HttpClient, DI captive dependencies, blocking async, N+1
- `libraries.md` — MediatR, FluentValidation, Mapster, ErrorOr, Polly, Aspire

Use these as supporting references only. Project `docs/STANDARDS.md`, SDD approvals, and the main skill guidance remain authoritative.

## References

- [.NET 10 Overview](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10/overview)
- [C# 14 What's New](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14)
- [C# compiler breaking changes for .NET 10](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/breaking-changes/compiler%20breaking-changes%20-%20dotnet%2010)
