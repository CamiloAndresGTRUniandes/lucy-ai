---
name: zenticalab-security
description: >
  OWASP Top 10 2025 security guidance for ZENTICALAB. Broken Access Control,
  Cryptographic Failures, Injection, and more — mapped to .NET + Angular.
metadata:
  author: lucy-camilo
  version: "1.0"
  project: ZENTICALAB
---

# ZENTICALAB Security — OWASP Top 10 2025 + Best Practices

Skill para asegurar ZENTICALAB contra las vulnerabilidades más críticas. Cada regla está mapeada al OWASP Top 10 2025.

> **Fuentes:** [OWASP Top 10 2025](https://owasp.org/Top10/2025/) | [Angular Security](https://angular.dev/best-practices/security) | [Microsoft OWASP Training](https://learn.microsoft.com/en-us/training/modules/owasp-top-10-for-dotnet-developers/)

---

## Regla de oro

> Seguridad no es feature — es requisito. Toda PR debe pasar el checklist de seguridad antes de merge. Si hay duda, preguntar antes de merge, no después.

---

## OWASP Top 10 2025 — Mapeo para ZENTICALAB

---

### A01:2025 — Broken Access Control

**Riesgo:** Un usuario accede a datos de otro tenant. En ZENTICALAB esto es crítico — schema-per-tenant significa que un acceso cruzado revela datos de OTRA dental lab.

#### Backend

**ZONA CRÍTICA — Multi-tenant:**
```csharp
// ❌ NUNCA hacer esto — acceso directo sin verificar tenant
[HttpGet("items/{id}")]
public async Task<IActionResult> GetItem(Guid id)
{
    var item = await _context.SupplyItems.FindAsync(id);
    return Ok(item);
}
```

** ✅ Correcto — siempre verificar tenant del contexto:**
```csharp
[HttpGet("items/{id}")]
[RequirePermissions("Inventario.Leer")]
public async Task<IActionResult> GetItem(Guid id, CancellationToken ct)
{
    var ctx = TenantHttpContext.GetTenantRequestContext(HttpContext);
    if (ctx is null) return Forbid();

    // El query SIEMPRE filtra por tenant schema
    var item = await _context.SupplyItems
        .FirstOrDefaultAsync(i => i.Id == id && i.TenantId == ctx.TenantId, ct);

    if (item is null) return NotFound();
    return Ok(item);
}
```

**Excepciones del middleware:**
- El `TenantResolutionMiddleware` inyecta el schema en cada request
- Cada query LINQ/EF Core sobre tablas tenant-debe usar el schema correcto
- **Nunca** hacer queries sobre `public.Suppliers` o `public.SupplyItems` — solo sobre el schema del tenant

**IDs en URLs (IDOR):**
```csharp
// ❌ URL con ID predecible — un atacante cambia el GUID
GET /tenant/inventory/items/3fa85f64-5717-4562-b3fc-2c963f66afa6

// ✅ Usar el TenantRequestContext — el ID del tenant viene del token, no de la URL
// El controller extrae el schema del contexto, no del usuario
```

**Regla de oro:** El `TenantId` o `TenantSchema` **nunca** se toma de la URL o query string. Siempre del JWT token / contexto de la request.

#### Frontend

- **Nunca** guardar `tenantId` o `tenantSchema` en `localStorage` como dato legible
- El `TenantAuthStore` debe obtener el schema exclusivamente del token JWT decodificado
- Los guards de ruta deben verificar que el tenant del componente coincide con el token

#### Checklist A01

- [ ] Todo controller tiene `[RequirePermissions]` en cada acción (no solo class-level)
- [ ] Queries LINQ siempre usan filtro de tenant
- [ ] IDs de recursos en URLs no son suficientes para autorización — verificar propiedad
- [ ] El schema del tenant se extrae del token JWT, no de headers o query params
- [ ] Logs NO contienen `TenantSchema` o `TenantId` de otros tenants

---

### A02:2025 — Security Misconfiguration

**Riesgo:** Headers faltantes, CORS abierto, DEBUG en producción, secrets en código.

#### Backend

**Headers de seguridad — `Program.cs`:**
```csharp
app.Use(async (context, next) =>
{
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Append("X-Frame-Options", "DENY");
    context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");
    context.Response.Headers.Append("Permissions-Policy", "geolocation=(), microphone=(), camera=()");
    await next();
});

// CSP + Trusted Types (A01 + Angular)
app.Use(async (context, next) =>
{
    context.Response.Headers.Append(
        "Content-Security-Policy",
        "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';");
    await next();
});
```

**CORS — nunca `AllowAnyOrigin()`:**
```csharp
// ❌
services.AddCors(options => options.AddPolicy("dev", b => b.AllowAnyOrigin()));

// ✅ — especificar orígenes exacta
services.AddCors(options => options.AddPolicy("allowed", b =>
{
    b.WithOrigins("https://zenticalab.com", "https://admin.zenticalab.com")
     .AllowCredentials()
     .AllowMethods("GET", "POST", "PUT", "DELETE")
     .AllowHeaders("Authorization", "Content-Type", "X-Requested-With");
}));
```

**Variables de entorno obligatorias antes de iniciar:**
```csharp
// En Program.cs — fail fast si faltan vars críticas
var jwtKey = builder.Configuration["Jwt__Key"];
if (string.IsNullOrWhiteSpace(jwtKey) || jwtKey.Length < 32)
    throw new InvalidOperationException("Jwt__Key must be at least 32 characters.");

// Similar para ConnectionStrings__DefaultConnection en producción
```

**DEBUG mode:**
```csharp
// appsettings.Production.json — nunca dejar "Debug" en prod
"Logging": {
  "LogLevel": {
    "Default": "Warning",
    "Microsoft.AspNetCore": "Warning"
  }
}
```

**Eliminar meta-info de errores:**
```csharp
// ❌ Stack traces en producción
app.UseDeveloperExceptionPage();

// ✅ Error genérico + log detallado internamente
app.UseExceptionHandler("/error");
app.UseStatusCodePagesWithReExecute("/error/{0}");
```

#### Frontend

- `environment.ts` (dev) puede tener API URL local; `environment.prod.ts` **nunca** commit
- `APP_ENV` production build usa siempre `NG_APP_API_URL` de env var
- No exponer `tenantId` o `apiKey` en archivos de código fuente

#### Checklist A02

- [ ] CORS whitelist específica, no `AllowAnyOrigin`
- [ ] Headers de seguridad (`X-Frame-Options`, `X-Content-Type-Options`, CSP)
- [ ] Vars críticas validadas al startup (fail-fast)
- [ ] `AllowAnonymous` solo en endpoints públicos (login, register, health)
- [ ] Secrets **nunca** en `appsettings.json` — solo en `.env` o Azure Key Vault
- [ ] Error handler genérico en producción — sin stack traces al cliente

---

### A03:2025 — Software Supply Chain Failures

**Riesgo:** Paquetes comprometidos, dependencias con vulnerabilidades, ataques a la cadena de suministro.

#### Backend

**Auditar dependencias NuGet:**
```bash
dotnet list package --outdated
dotnet restore && dotnet audit
```

**Fijar versiones exactas en producción:**
```xml
<!-- Central Package Management (Directory.Packages.props) -->
<PackageReference Update="FluentValidation.AspNetCore" Version="11.3.0" />
```
No usar `Version="*"` — fija la versión para que `dotnet restore` sea determinístico.

**Verificar origen de paquetes:**
```bash
# Solo usar nuget.org como fuente en producción
dotnet nuget list source
```

**GitHub Actions — dependencias en PRs:**
```yaml
# En workflow de PR
- name: Check for vulnerable dependencies
  run: dotnet audit --ignore-failed-source
```

#### Frontend

```bash
# Auditar vulnerabilidades npm
npm audit --audit-level=high

# Verificar licencia de paquetes (evitar dependencias con licencias restrictivas)
npx license-checker --summary
```

**No instalar paquetes de fuentes no verificadas:**
- Solo `npm install` desde `package.json` de confianza
- Verificar el repo GitHub de paquetes nuevos antes de instalar

#### Checklist A03

- [ ] `dotnet audit` pasa sin errores en CI
- [ ] `npm audit` pasa sin errores en CI
- [ ] Paquetes con versiones fijas (no `latest`)
- [ ] Revisar cambios en `package-lock.json` / `obj/project.assets.json` en cada PR
- [ ] No instalar herramientas o scripts random de internet en el pipeline

---

### A04:2025 — Cryptographic Failures

**Riesgo:** Datos sensibles en texto plano, algoritmos débiles, keys hardcodeadas.

#### Backend

**JWT — algoritmo y key:**
```csharp
// ❌ Algoritmo débil o key corta
var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("short-key"));

// ✅ HS256 + key de al menos 256 bits (32 chars min)
var key = new SymmetricSecurityKey(
    Encoding.UTF8.GetBytes(_configuration["Jwt__Key"] ?? throw new InvalidOperationException()));
```

**No guardar datos sensibles en texto plano:**
```csharp
// ❌
public class SupplierDto { public string Nit { get; set; } public string BankAccount { get; set; } }

// ✅ — solo campos necesarios para la operación; nunca exponer cuentas bancarias
// en DTOs públicos sin necesidad de negocio
```

**Hash de passwords:**
- ZENTICALAB usa ASP.NET Core Identity con bcrypt — **no implementar hash propio**
- Si se usa custom password hash, usar `BCrypt.Net-Next`

**TLS en producción:**
```csharp
// Force HTTPS en producción
app.UseHsts();
app.UseHttpsRedirection();
```

**Certificados:**
- Azurite usa clave hardcodeada en dev — **nunca en prod**
- Producción: Azure Blob Storage con Managed Identity, no connection strings

#### Checklist A04

- [ ] JWT key >= 32 caracteres
- [ ] TLS habilitado en producción (no HTTP plain)
- [ ] Connection strings no commitidas (`.env` en `.gitignore`)
- [ ] Secrets de prod en Azure Key Vault, no en config files
- [ ] No hardcodear credenciales — usar `IConfiguration` o env vars
- [ ] Sensitive data no se serializa en logs

---

### A05:2025 — Injection

**Riesgo:** SQL injection, XSS, command injection.

#### Backend — SQL Injection

**ZENTICALAB usa EF Core + raw SQL:**
```csharp
// ❌ String concatenation en raw SQL
var sql = $"SELECT * FROM \"{schema}\".\"Items\" WHERE name LIKE '%{userInput}%'";

// ✅ Parameterized query via SqlQueryRaw o EF Core
await _context.Database
    .SqlQueryRaw<SupplyItemRow>(
        $"SELECT * FROM \"{safeSchema}\".\"SupplyItems\" WHERE \"Name\" LIKE {{{0}}}",
        $"%{sanitized}%")
```

**Validación de input con FluentValidation:**
```csharp
public class CreateSupplyItemValidator : AbstractValidator<CreateSupplyItemRequestDto>
{
    public CreateSupplyItemValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().MaximumLength(255)
            .Matches(@"^[a-zA-Z0-9\s\-áéíóúÁÉÍÓÚñÑ]+$")
            .WithMessage("Nombre solo puede contener letras, números, espacios y guiones.");

        RuleFor(x => x.Nit)
            .NotEmpty()
            .Matches(@"^\d{9,15}-?\d$")
            .WithMessage("NIT inválido.");
    }
}
```

**Schema validation:**
```csharp
// El TenantSqlBuilder valida que el schema name sea seguro
var safeSchema = TenantSqlBuilder.ValidateSchema(context.TenantSchema);
// Valida: no SQL keywords, longitud máxima, caracteres válidos
```

#### Frontend — XSS

**Angular sanitiza por defecto, pero:**
```html
<!-- ❌ — vulnerable si userInput contiene <script> -->
<div [innerHTML]="userProvidedHtml"></div>

<!-- ✅ — Angular sanitiza automáticamente -->
<div>{{ userInput }}</div>

<!-- Si innerHTML es necesario (contenido de editor tipo rich text): -->
```

> ⚠️ **WARNING:** `bypassSecurityTrustHtml` disables ALL Angular sanitization. This reintroduces XSS risk if the HTML comes from user input. Use ONLY with fully trusted, server-curated content. Never pass user-provided strings through this method.

```typescript
import { DomSanitizer } from '@angular/platform-browser';

constructor(private sanitizer: DomSanitizer) {}

getSafeHtml(html: string) {
  return this.sanitizer.bypassSecurityTrustHtml(html);
}
```

**Nunca usar `eval()` ni `new Function()` en Angular:**
```typescript
// ❌
eval(`console.log('${userInput}')`);

// ✅ — no hay caso válido para eval en ZENTICALAB
```

**Content Security Policy en Angular:**
```typescript
// angular.json — enforce CSP headers
{
  "production": {
    "headers": {
      "Content-Security-Policy": "default-src 'self'; style-src 'self' 'unsafe-inline'"
    }
  }
}
```

#### Checklist A05

- [ ] Raw SQL usa parámetros, nunca string concatenation
- [ ] FluentValidation en todos los DTOs de entrada
- [ ] Schema name del tenant validado contra SQL keywords
- [ ] innerHTML solo con contenido trusted (no user-provided HTML)
- [ ] No usar `eval()`, `new Function()`, `innerHTML` con input de usuario
- [ ] Input de formularios sanitizado antes de persistir

---

### A06:2025 — Insecure Design

**Riesgo:** Architecture flaws — autenticación débil, no rate limiting, ausencia de locks.

#### Backend

**Rate limiting por tenant:**
```csharp
// En Program.cs
builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy("PerTenant", context =>
    {
        var tenant = context.User.FindFirst("tenant_schema")?.Value ?? "anonymous";
        return RateLimitPartition.GetFixedWindowLimiter(tenant, _ =>
            new FixedWindowRateLimiterOptions
            {
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1)
            });
    });
});

// Controller
[HttpGet]
[EnableRateLimiting("PerTenant")]
[RequirePermissions("Inventario.Leer")]
public async Task<IActionResult> GetAlerts(...) { ... }
```

**Account lockout:**
```csharp
// En configuración de Identity
services.Configure<IdentityOptions>(options =>
{
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
});
```

**Missing auth on new endpoint — fail-safe:**
```csharp
// Cada controller nuevo debe tener [Authorize] o [RequirePermissions]
// Si se olvida, el middleware de audit loggea elgap
```

#### Checklist A06

- [ ] Rate limiting activo en endpoints públicos y de alta frecuencia
- [ ] Account lockout configurado (max attempts + lockout duration)
- [ ] Flujo de "forgot password" con token de un solo uso + expiración
- [ ] Registro de actividad sospechosa (fallos de login repetidos)

---

### A07:2025 — Authentication Failures

**Riesgo:** Sesiones robadas, tokens sin expiración, credenciales en URL.

#### Backend

**JWT — expiración obligatoria:**
```csharp
var tokenDescriptor = new SecurityTokenDescriptor
{
    Subject = new ClaimsIdentity(new[]
    {
        new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
        new Claim("tenant_schema", tenantSchema),
        new Claim("tenant_id", tenantId.ToString())
    }),
    Expires = DateTime.UtcNow.AddMinutes(
        double.Parse(_configuration["Jwt__ExpiryMinutes"] ?? "60")),
    Issuer = _configuration["Jwt__Issuer"],
    Audience = _configuration["Jwt__Audience"],
    SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
};
```

**Refresh tokens:**
```csharp
// Refresh token con rotación (invalidar al usar)
var refreshToken = new RefreshToken
{
    Value = GenerateSecureToken(),
    TenantId = tenantId,
    UserId = userId,
    ExpiresAt = DateTime.UtcNow.AddDays(7),
    IsRevoked = false
};
// Al usar refresh: marcar el viejo como revoked + guardar el nuevo (previene replay)
```

**Logout — invalidar token:**
```csharp
[HttpPost("logout")]
[Authorize]
public async Task<IActionResult> Logout()
{
    // Si se usa blacklisting: agregar token a lista negra con TTL = remaining token lifetime
    // Si se usa refresh rotation: revoke refresh token
    return Ok();
}
```

**2FA (para admins):**
```csharp
// Middleware de 2FA para operaciones sensibles (borrar tenant, cambiar roles)
[RequirePermissions("Admin.GestionUsuarios", Require2FA = true)]
public async Task<IActionResult> DeleteUser(Guid userId) { ... }
```

#### Frontend

**Token storage — NUNCA en localStorage para XSS:**
```typescript
// ❌ — vulnerable a XSS steal
localStorage.setItem('accessToken', token);
```

HttpOnly cookies MUST be set by the backend via `Set-Cookie` response header, not from JavaScript.

```http
Set-Cookie: accessToken=...; HttpOnly; Secure; SameSite=Strict
```

```typescript
// ✅ JavaScript can only set non-HttpOnly cookies when absolutely necessary
document.cookie = 'accessToken=...; Secure; SameSite=Strict'; // HttpOnly is set by the backend, not here
```

**Si se usa storage (para ZENTICALAB multi-tenant con JWT):**
- Usar `memory` signal store (en vez de localStorage) para tokens
- El `TenantAuthStore` guarda el JWT en una signal, no en localStorage
- Solo el refresh token (si existe) en httpOnly cookie

```typescript
// ✅ Signal-based memory store (se pierde al cerrar tab — es intencional)
export const authStore = {
  token: signal<string | null>(null),
  tenantSchema: signal<string | null>(null),
};
```

**Logout limpio:**
```typescript
logout() {
  this.authStore.token.set(null);
  this.authStore.tenantSchema.set(null);
  // Limpiar cookies de refresh si las hay
  document.cookie = 'refreshToken=; Max-Age=0; Secure';
}
```

#### Checklist A07

- [ ] JWT con `Expires` siempre setteado
- [ ] Refresh token con rotación y TTL <= 7 días
- [ ] Logout invalida tokens (blacklist o revoke)
- [ ] Refresh tokens en httpOnly cookies (no localStorage)
- [ ] Máximo 5 intentos de login antes de lockout
- [ ] Angular auth store en memoria, no localStorage

---

### A08:2025 — Software or Data Integrity Failures

**Riesgo:** Pipelines de CI/CD comprometidos, dependencias sin verificar.

#### Backend

**GitHub Actions — no confiar en artifacts de PRs sin verificar:**
```yaml
# ❌ PR de stranger puede sobreescribir secretos
- run: dotnet build
  env:
    JWT_KEY: ${{ secrets.JWT_KEY }}

# ✅ — solo desde branches verificados
- name: Build
  if: github.event.pull_request.merged == true
  run: dotnet build --configuration Release
```

**Verificar integridad de deps:**
```bash
# Verificar hash de packages contra lock files
dotnet restore --locked-mode
```

**Migraciones de DB firmadas (para producción futura):**
- Migrations son código que modifica el schema — tratarlas como código de producción

#### Checklist A08

- [ ] Secrets nunca en logs de CI/CD
- [ ] Solo merges a main requieren approval + CI passing
- [ ] `dotnet restore --locked-mode` en producción

---

### A09:2025 — Security Logging and Alerting Failures

**Riesgo:** Ataques pasan desapercibidos porque no hay logs.

#### Backend

**Log de seguridad — siempre incluir:**
```csharp
_logger.LogWarning(
    "AUTH_FAILURE: Tenant={TenantSchema} User={UserEmail} IP={IpAddress} " +
    "Attempt={AttemptNumber} Reason={Reason}",
    tenantSchema, email, ipAddress, attemptCount, failureReason);
```

**Loguear SIN exponer datos sensibles:**
```csharp
// ❌
_logger.LogInformation("User {Password} login failed", password);

// ✅
_logger.LogInformation("User login failed for email={Email}", email[..3] + "***");
```

**Events de seguridad a registrar:**
| Evento | Nivel | Datos |
|--------|-------|-------|
| Login exitoso | Info | Tenant, user, IP, timestamp |
| Login fallido | Warning | Tenant, email, IP, razón, intento # |
| Logout | Info | Tenant, user |
| Token refresh | Debug | Tenant, user |
| Acceso denegado (403) | Warning | Tenant, user, recurso, IP |
| Cambio de rol | Warning | Admin que lo hizo, target user, rol nuevo |
| Delete de tenant | Error | Admin, tenant schema, timestamp |

**Alertas — SIEMPRE notificar:**
- >5 login fallidos desde la misma IP en 10 min → alerta al admin
- Acceso denegado a recurso desde cuenta con permisos previos
- Queries SQL que fallen por timeout (posible enumeración)

#### Checklist A09

- [ ] Login/logout/403/errores de auth loggeados
- [ ] Logs no contienen passwords, tokens, o datos sensibles
- [ ] Logs tienen `TenantSchema` para auditoría multi-tenant
- [ ] Alertas configuradas para anomalías (>N login failures, acceso cruzado)

---

### A10:2025 — Mishandling of Exceptional Conditions

**Riesgo:** Excepciones no manejadas revelan información interna; denegación de servicio por errores no manejados.

#### Backend

**Global exception handler:**
```csharp
// En Program.cs
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        context.Response.StatusCode = 500;
        context.Response.ContentType = "application/json";

        var error = context.Features.Get<IExceptionHandlerFeature>();
        var exception = error?.Error;

        _logger.LogError(exception,
            "Unhandled exception. TraceId={TraceId}",
            context.TraceIdentifier);

        await context.Response.WriteAsJsonAsync(new
        {
            error = "An error occurred processing your request.",
            traceId = context.TraceIdentifier
        });
    });
});
```

**Nunca propagar mensajes de excepción interna al cliente:**
```csharp
// ❌ — revela información de implementación
catch (SqlException ex)
{
    return BadRequest($"Database error: {ex.Message}");
}

// ✅ — mensaje genérico, detalle en logs
catch (SqlException ex)
{
    _logger.LogError(ex, "DB error in GetSupplyItems for tenant {Schema}", schema);
    return StatusCode(503, "Service temporarily unavailable.");
}
```

**Null-check riguroso:**
```csharp
// ❌ — NullReferenceException si el join falla silenciosamente
var supplier = context.Suppliers.FirstOrDefault(s => s.Id == dto.SupplierId);
return Ok(new { supplier.RazonSocial }); // Puede ser null

// ✅ — fail explícito
var supplier = context.Suppliers.FirstOrDefault(s => s.Id == dto.SupplierId)
    ?? throw new InvalidOperationException($"Supplier {dto.SupplierId} not found in tenant {schema}");
```

**Timeout en queries:**
```csharp
// Queries sobre tablas con mucho dato — timeout para evitar DoS
await _context.SupplyItems
    .Where(i => i.TenantId == tenantId)
    .Take(1000)  // Limitar resultados
    .ToListAsync(cancellationToken);
```

#### Frontend

**Manejo de errores en services:**
```typescript
// ❌
return this.http.get('/api/items').pipe(
  map(items => items) // No maneja error
);

// ✅
return this.http.get<Item[]>(`${environment.apiUrl}/items`).pipe(
  map(items => items),
  catchError(err => {
    if (err.status === 401) {
      this.authStore.token.set(null);
      this.router.navigate(['/login']);
    }
    return throwError(() => err);
  })
);
```

#### Checklist A10

- [ ] Exception handler global devuelve mensaje genérico al cliente
- [ ] Todos los logs de excepción tienen TraceId para correlación
- [ ] Queries tienen timeout y límites de resultados (pagination mandatory)
- [ ] Errores HTTP 4xx/5xx manejados en todos los interceptors de Angular
- [ ] Null-check en todas las operaciones de base de datos antes de usar el resultado

---

## Checklist de seguridad — Pre-PR

Copiar y marcar antes de cada PR:

### Backend
- [ ] `[RequirePermissions]` en cada acción del controller
- [ ] Queries filtran por `TenantSchema` del contexto
- [ ] DTOs validados con FluentValidation
- [ ] No hay secrets, passwords o tokens en logs
- [ ] Excepciones no propagan mensajes internos al cliente
- [ ] Rate limiting en endpoints nuevos
- [ ] `dotnet audit` pasa
- [ ] Vars críticas validadas al startup

### Frontend
- [ ] Tokens en signal store (no localStorage)
- [ ] Errores HTTP 4xx/5xx manejados en service
- [ ] No `eval()`, `new Function()`, ni `innerHTML` con input de usuario
- [ ] Rutas protegidas con guard que verifica auth
- [ ] `npm audit` pasa
- [ ] CSP headers configurados

---

## Referencias

- [OWASP Top 10 2025](https://owasp.org/Top10/2025/)
- [OWASP Top 10 .NET Developers](https://learn.microsoft.com/en-us/training/modules/owasp-top-10-for-dotnet-developers/)
- [Angular Security](https://angular.dev/best-practices/security)
- [ASP.NET Core Security Best Practices](https://learn.microsoft.com/en-us/aspnet/core/security/best-practices)
