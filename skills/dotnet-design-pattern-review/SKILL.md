---
name: dotnet-design-pattern-review
description: >
  Review .NET/C# code for appropriate design pattern usage, SOLID, dependency boundaries,
  testability, and over/under-engineering. Trigger: when reviewing design patterns in .NET code.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# .NET/C# Design Pattern Review

## When to Use

Use when reviewing whether .NET code applies patterns appropriately or needs simpler structure.

## Rules

- Do not require patterns just because they exist.
- Prefer the simplest design that satisfies current and near-term requirements.
- Flag both under-engineering and over-engineering.
- Check repo standards before recommending architectural changes.

## Review Checklist

- [ ] Responsibilities are cohesive and easy to name.
- [ ] Dependencies point in the intended direction.
- [ ] Interfaces improve testability or boundary control instead of adding ceremony.
- [ ] Factories/builders are used only where construction complexity justifies them.
- [ ] Strategy/policy patterns replace fragile conditionals where variants are expected to grow.
- [ ] Repository/query patterns do not hide important query behavior or cause N+1 issues.
- [ ] Options/configuration are strongly typed and validated where critical.
- [ ] Resource disposal and async patterns are correct.
- [ ] Error handling and logging are consistent.
- [ ] Tests can exercise behavior without brittle infrastructure coupling.

## Output

Provide concrete findings with file/line evidence and a recommended simpler or safer alternative.
