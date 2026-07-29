---
name: csharp-async
description: >
  C# async/await best practices for naming, return types, cancellation, exception handling,
  concurrency, deadlock prevention, and async streams. Trigger: when writing or reviewing C# async code.
license: Apache-2.0
metadata:
  author: imported-and-adapted-by-lucy-camilo
  version: "1.1"
---

# C# Async Programming Best Practices

## When to Use

Use when writing or reviewing asynchronous C# code, especially I/O, APIs, background work, concurrent calls, or cancellation.

## Core Rules

- Use the `Async` suffix for async methods unless the framework convention says otherwise.
- Return `Task<T>` for values and `Task` for no value.
- Avoid `async void` except event handlers.
- Do not block on async code with `.Wait()`, `.Result`, or `.GetAwaiter().GetResult()`.
- Always propagate or handle exceptions intentionally; never swallow them silently.
- Accept and pass `CancellationToken` for long-running, I/O, request, and background operations.
- Use `ConfigureAwait(false)` mainly in library code where resuming the original context is unnecessary.
- Avoid unnecessary `async`/`await` when simply returning a task and no try/finally/using/context behavior is needed.

## Concurrency Patterns

- Use `Task.WhenAll()` for independent parallel operations.
- Use `Task.WhenAny()` for first-completed workflows or timeout races.
- Bound concurrency for large collections; do not create unbounded fan-out.
- Use `IAsyncEnumerable<T>` for streaming async sequences.
- Use `ValueTask<T>` only for measured high-performance paths where it is justified.

## Review Checklist

- [ ] No sync-over-async blocking.
- [ ] Cancellation is accepted and propagated.
- [ ] Parallelism is bounded when input size can grow.
- [ ] Exceptions preserve stack traces and context.
- [ ] Async names/return types follow conventions.
- [ ] Fire-and-forget work is explicitly supervised/logged.
