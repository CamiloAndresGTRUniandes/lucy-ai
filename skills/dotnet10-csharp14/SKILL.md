---
name: dotnet10-csharp14
description: >
  .NET 10 + C# 14 best practices for ZENTICALAB. field keyword, params Span,
  field-backed properties, and other C# 14 features for Clean Architecture.
metadata:
  author: lucy-camilo
  version: "1.0"
  project: ZENTICALAB
---

# .NET 10 + C# 14 — ZENTICALAB Best Practices

Skill para usar .NET 10 y C# 14 con las mejores prácticas en el codebase ZENTICALAB.

## Fuente
- [.NET 10 Overview](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10/overview) (LTS, 3 años de soporte)
- [C# 14 What's New](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14)

## Regla de adopción

> Solo aplicar features de C# 14 / .NET 10 cuando mejoren expresividad, seguridad o performance del código existente. **No reescribir código funcional solo por usar features nuevas.**

---

## C# 14 — Features de alto impacto para ZENTICALAB

### 1. `field` keyword — Properties con validación inline

**Antes (C# 13):**
```csharp
private string _name;
public string Name
{
    get => _name;
    set => _name = value ?? throw new ArgumentNullException(nameof(value));
}
```

**Con C# 14 `field`:**
```csharp
public string Name
{
    get;
    set => field = value ?? throw new ArgumentNullException(nameof(value));
}
```

**Dónde usar en ZENTICALAB:**
- DTOs con validación `value ?? throw` — FluentValidation ya cubre esto, pero útil para setters internos rápidos
- Entidades con invariantes de dominio simples

**Cuidado:** Si la clase tiene un símbolo llamado `field`, usar `@field` o `this.field` para desambiguar.

---

### 2. Null-conditional assignment — `?.=`

**Antes:**
```csharp
if (customer is not null)
{
    customer.Order = GetCurrentOrder(); // GetCurrentOrder() se evalúa aunque customer sea null
}
```

**Con C# 14:**
```csharp
customer?.Order = GetCurrentOrder(); // GetCurrentOrder() NO se llama si customer es null
```

**Dónde usar en ZENTICALAB:**
- Asignación de propiedades en servicios donde el target puede ser null
- Logging con campos opcionales
- UI state en componentes que pueden desmontarse

**No usar con:** incremento/decremento (`++` / `--`) — no permitido en C# 14.

---

### 3. Extension members — Extension properties y static extension methods

```csharp
public static class InventoryAlertExtensions
{
    extension<T>(IList<T> list)
    {
        // Extension property
        public bool IsEmpty => list.Count == 0;

        // Extension method
        public IList<T> AddIfNotNull(T? item) where T : class
        {
            if (item is not null) list.Add(item);
            return list;
        }
    }

    // Static extension — se invoca como IEnumerable<int>.Identity
    extension<T>(IEnumerable<T>)
    {
        public static IEnumerable<T> EmptyOrSelf(IEnumerable<T>? source)
            => source ?? Enumerable.Empty<T>();
    }
}
```

**Dónde usar en ZENTICALAB:**
- `IsEmpty` para null-safety de listas
- `EmptyOrSelf()` para reemplazar `?? Enumerable.Empty<T>()` de forma más legible
- Operadores estáticos personalizados para tipos de dominio

---

### 4. `nameof(List<>)` — Unbound generics

```csharp
// C# 13
nameof(List<int>)  // "List"

// C# 14 — unbound generic
nameof(List<>)     // "List"
nameof(Dictionary<,>)  // "Dictionary"
```

**Dónde usar en ZENTICALAB:**
- Atributos `[JsonPropertyName]` con tipos genéricos
- Validación runtime de tipo genérico sin instanciar

---

### 5. Partial constructors y partial events

```csharp
public partial class TenantSchemaMigrator
{
    // Defining declaration
    partial void OnMigrationFailed(string schema, Exception ex);

    // Implementing declaration
    partial void OnMigrationFailed(string schema, Exception ex)
    {
        _telemetry.TrackFailure(schema, ex);
    }
}
```

**Dónde usar en ZENTICALAB:**
- `TenantSchemaMigrator` — ya usa partial class, puede separar logging/telemetry
- Separación de concerns en constructors de entidades complejas

---

### 6. Lambda parameter modifiers sin tipo explícito

```csharp
// C# 13 — requería tipos explícitos
Func<string, int, bool> tryParse = (string text, out int result)
    => int.TryParse(text, out result);

// C# 14 — modificador sin tipo
Func<string, int, bool> tryParse = (text, out result)
    => int.TryParse(text, out result);
```

**Dónde usar en ZENTICALAB:**
- Delegates con `out` / `ref` / `in`
- Callbacks con muchos parámetros en servicios

---

## .NET 10 Runtime — Relevante para ZENTICALAB

### JIT Inlining y devirtualization mejorados
Métodos pequeños ahora se inline más agresivamente. Queries SQL en servicios como `InventoryAlertService` pueden ejecutarse más rápido sin cambios de código.

### NativeAOT enhancements
Start-up más rápido. **Aplicable a:** Azure Functions, serverless. Para ZENTICALAB (containers/IIS) es menos crítico.

### AVX10.2 support
Optimización vectorizada para operaciones numéricas. **Aplicable a:** reportes, cálculo de inventario.

---

## ASP.NET Core 10

### OpenAPI improvements
- Mejorado soporte para Required properties en schemas
- Validación de form data más estricta

### Blazor preloading (WebAssembly)
- Si el frontend usa Blazor, carga más rápida en segunda visita

---

## EF Core 10 (si actualizan desde EF Core 9)

### Named query filters
```csharp
modelBuilder.Entity<SupplyItem>()
    .HasQueryFilter(s => s.TenantId == _tenantId, "TenantFilter");
modelBuilder.Entity<SupplyItem>()
    .IgnoreQueryFilter("TenantFilter");
```
**ZENTICALAB ya maneja tenant filtering via middleware — no cambiar la estrategia existente.**

### LINQ enhancements
- Mejor inferencia de tipos en queries complejas
- Traducción más eficiente de `string.Join` a SQL

---

## Checklist para usar C# 14 / .NET 10 en ZENTICALAB

- [ ] La feature mejora el código, no solo lo cambia
- [ ] Todos los devs tienen .NET 10 SDK instalado
- [ ] Tests existentes siguen pasando
- [ ] No contradice Clean Architecture (lógica de dominio en Domain layer, no en presentation)
- [ ] No rompe compatibilidad con entornos de producción existentes

---

## Referencias

- [.NET 10 Overview](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10/overview)
- [C# 14 What's New](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14)
- [C# 14 Breaking Changes](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/breaking-changes/compiler%20breaking-changes%20-%20dotnet%2010)
