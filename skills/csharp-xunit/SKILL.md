---
name: csharp-xunit
description: >
  xUnit testing guidance for C# projects including facts, theories, fixtures, assertions,
  async tests, data-driven tests, and test organization. Trigger: when writing or reviewing xUnit tests.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# xUnit Best Practices

## When to Use

Use when writing or reviewing C# tests that use xUnit.

## Test Structure

- Use `[Fact]` for single-scenario tests.
- Use `[Theory]` with `[InlineData]`, `[MemberData]`, or `[ClassData]` for data-driven tests.
- Follow Arrange → Act → Assert.
- Name tests by behavior, commonly `Method_Scenario_ExpectedBehavior` unless repo standards differ.
- Keep tests independent and deterministic.
- Avoid multiple unrelated behaviors in one test.

## Fixtures and Setup

- Constructor = per-test setup.
- `IDisposable` / `IAsyncLifetime` = teardown or async lifecycle.
- `IClassFixture<T>` = shared context for one test class.
- `ICollectionFixture<T>` = shared context across multiple classes.
- Avoid shared mutable state unless explicitly controlled.

## Assertions

- Prefer clear assertions that express intent.
- Use `Assert.Throws<T>` / `Assert.ThrowsAsync<T>` for exceptions.
- Use FluentAssertions if the repo already uses it or standards allow it.

## Review Checklist

- [ ] Tests cover success and failure paths.
- [ ] Async code is awaited properly.
- [ ] Tests are deterministic and order-independent.
- [ ] Test data names communicate intent.
- [ ] Integration tests isolate external dependencies appropriately.
