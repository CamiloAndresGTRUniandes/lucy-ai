---
name: csharp-dotnet
description: >
  C# and .NET patterns for OpenClaw. Triggers when writing C#, implementing .NET APIs, working with EF Core, or making architecture decisions in .NET projects.
  Use for: Clean Architecture, dependency injection, async patterns, Result pattern, Minimal APIs, EF Core queries, and unit testing in C#.
metadata:
  author: lucy-camilo
  version: "1.0"
---

## Clean Architecture (REQUIRED)

```
src/
├── Domain/           # Entities, value objects, interfaces — NO dependencies
├── Application/      # Use cases, DTOs, repository interfaces
├── Infrastructure/   # EF Core, external services
└── API/             # Controllers, Minimal APIs, middleware
```

**Rule:** Dependencies only point inward. Domain knows nothing.

---

## Dependency Injection (REQUIRED)

```csharp
// ALWAYS: Interface-based DI
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();

// DbContext always Scoped
builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseSqlServer(connectionString));

// AutoMapper
builder.Services.AddAutoMapper(typeof(MappingProfile));
```

| Lifetime | Use |
|---|---|
| **Scoped** | DbContext, Repositories, Services (per-request state) |
| **Transient** | Lightweight stateless services |
| **Singleton** | Config, global caching |

---

## Entity Framework Core (REQUIRED)

### DbContext

```csharp
public class AppDbContext : DbContext
{
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Email).IsRequired().HasMaxLength(256);
            entity.HasIndex(e => e.Email).IsUnique();
        });

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
```

### Query patterns

```csharp
// Eager loading — NO lazy loading in production
var users = await context.Users
    .Include(u => u.Orders)
    .Where(u => u.IsActive)
    .Select(u => new UserDto { Id = u.Id, Email = u.Email })
    .ToListAsync(ct);
```

---

## Async/Await (REQUIRED)

```csharp
// ALWAYS async at API boundary
[HttpGet("{id}")]
public async Task<ActionResult<UserDto>> GetById(int id, CancellationToken ct)
{
    var user = await _service.GetByIdAsync(id, ct);
    return user is null ? NotFound() : Ok(user);
}

// CancellationToken on every async operation
public async Task<UserDto?> GetByIdAsync(int id, CancellationToken ct = default)
{
    ct.ThrowIfCancellationRequested();
    return await _repository.GetByIdAsync(id, ct);
}
```

---

## Result Pattern (REQUIRED for business logic)

```csharp
public record Result<T>(T? Value, Error? Error)
{
    public bool IsSuccess => Error is null;
    public bool IsFailure => !IsSuccess;

    public static Result<T> Success(T value) => new(value, null);
    public static Result<T> Failure(Error error) => new(default, error);
}

public record Error(string Code, string Message);

// Usage
public async Task<Result<OrderDto>> CreateOrderAsync(CreateOrderCommand cmd, CancellationToken ct)
{
    if (!await _userRepository.ExistsAsync(cmd.UserId, ct))
        return Result<OrderDto>.Failure(new Error("USER_NOT_FOUND", "User does not exist"));

    var order = await _repository.CreateAsync(cmd, ct);
    return Result<OrderDto>.Success(_mapper.Map<OrderDto>(order));
}
```

---

## Error Handling (REQUIRED)

```csharp
// NEVER swallow exceptions
try { }
catch (Exception ex)
{
    _logger.LogError(ex, "Error processing request {Id}", requestId);
    throw;  // Always rethrow
}

// Global exception handler
app.UseExceptionHandler(appBuilder =>
{
    appBuilder.Run(async context =>
    {
        var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;
        var (statusCode, message) = exception switch
        {
            ValidationException => (400, exception.Message),
            NotFoundException => (404, exception.Message),
            _ => (500, "An error occurred")
        };

        context.Response.StatusCode = statusCode;
        await context.Response.WriteAsJsonAsync(new { error = message });
    });
});
```

---

## Minimal APIs (PREFERRED over Controllers for new APIs)

```csharp
public static class UserEndpoints
{
    public static void MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/users").WithTags("Users");

        group.MapGet("/", async (IUserService svc, CancellationToken ct) =>
            Results.Ok(await svc.GetAllAsync(ct)));

        group.MapGet("/{id:int}", async (int id, IUserService svc, CancellationToken ct) =>
        {
            var user = await svc.GetByIdAsync(id, ct);
            return user is null ? Results.NotFound() : Results.Ok(user);
        });

        group.MapPost("/", async (CreateUserRequest req, IUserService svc, CancellationToken ct) =>
        {
            var result = await svc.CreateAsync(req, ct);
            return result.IsSuccess
                ? Results.Created($"/api/users/{result.Value!.Id}", result.Value)
                : Results.BadRequest(result.Error);
        });
    }
}
```

---

## Record Types

```csharp
// ALWAYS records for DTOs (immutable)
public record UserDto(int Id, string Email, string FullName);

// With validation
public record CreateUserRequest
{
    public string Email { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;

    public ValidationResult Validate() => /* ... */;
}

// Classes for entities (mutable — EF needs this)
public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public ICollection<Order> Orders { get; set; } = new List<Order>();
}
```

---

## LINQ Patterns

```csharp
// Method syntax over query syntax (more readable in chains)
var result = users
    .Where(u => u.IsActive && u.Role == Role.Admin)
    .OrderBy(u => u.FullName)
    .Select(u => new { u.Id, u.Email })
    .ToListAsync(ct);

// Pagination
var items = await query
    .OrderBy(u => u.FullName)
    .Skip((page - 1) * pageSize)
    .Take(pageSize)
    .ToListAsync(ct);
```

---

## Testing

```csharp
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _repoMock = new();
    private readonly UserService _sut = new(_repoMock.Object);

    [Fact]
    public async Task GetByIdAsync_WhenUserExists_ReturnsUser()
    {
        // Arrange
        var userId = 1;
        var user = new User { Id = userId, Email = "test@test.com" };
        _repoMock.Setup(r => r.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(user);

        // Act
        var result = await _sut.GetByIdAsync(userId);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("test@test.com", result!.Email);
    }
}
```

**Naming:** `[Method]_[Scenario]_[ExpectedResult]`

---

## Project Structure Options

### Clean Architecture (complex/domain-driven)

```
src/
├── Domain/Entities/, ValueObjects/, Interfaces/
├── Application/UseCases/, DTOs/, Interfaces/, Services/
├── Infrastructure/Data/, Repositories/, Services/
└── API/Controllers/, Middleware/, Filters/
```

### Layered (simpler projects)

```
src/
├── ProjectName.Core/      # Business logic, entities
├── ProjectName.Infrastructure/ # Data access
└── ProjectName.API/       # Controllers, middleware
```

---

## Code Style

- **Namespaces:** Singular (`ProjectName.Domain.Entities`)
- **Properties over fields:** Always
- **Braces:** Consistent with project (team decision)
- **Structured logging:**

```csharp
_logger.LogInformation(
    "Creating order {OrderId} for user {UserId}",
    orderId, userId);
```

---

## Performance

```csharp
// NO: N queries
foreach (var id in ids)
    var user = context.Users.Find(id);

// YES: 1 query
var users = await context.Users
    .Where(u => ids.Contains(u.Id))
    .ToListAsync();
```
