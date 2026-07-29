---
name: csharp-docs
description: >
  C# XML documentation guidance for public APIs, parameters, returns, exceptions, examples,
  inheritdoc, and documentation quality. Trigger: when documenting or reviewing C# public APIs.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# C# Documentation Best Practices

## When to Use

Use when documenting or reviewing public C# APIs, libraries, SDKs, shared components, or complex internal members.

Repo standards decide how strict XML documentation requirements are.

## XML Comment Guidance

- Public members should have XML comments when they are part of a public/shared API.
- Complex internal members should be documented when intent is not obvious.
- Use `<summary>` for a brief one-sentence description.
- Use `<remarks>` for deeper usage notes, tradeoffs, or implementation context.
- Use `<param>`, `<typeparam>`, and `<returns>` for parameters, generic type parameters, and return values.
- Use `<exception cref="...">` for exceptions callers are expected to handle.
- Use `<see cref="...">`, `<seealso>`, `<paramref>`, and `<typeparamref>` for references.
- Use `<inheritdoc/>` when implementation behavior matches inherited contract.
- Use `<example><code language="csharp">...</code></example>` for useful examples.

## Wording Patterns

- Constructor summary: “Initializes a new instance of the `<Type>` class.”
- Boolean property: “Gets a value indicating whether ...”
- Boolean parameter: “`true` to ...; otherwise, `false`.”
- Avoid repeating obvious type information; document meaning and constraints instead.

## Review Checklist

- [ ] Public API purpose is clear.
- [ ] Parameters explain meaning, units, constraints, and nullability where relevant.
- [ ] Exceptions are documented without leaking implementation noise.
- [ ] Examples compile conceptually and do not include secrets.
- [ ] Documentation matches current behavior.
