# Comparison with Alternatives

This document compares fast-uuid with other UUID libraries available for Ruby, helping you understand when to use each.

## Overview

| Library | Versions | Dependencies | Key Features | Performance |
|---------|----------|--------------|--------------|-------------|
| **fast-uuid** | v1, v3, v4, v5, v6, v7 | Zero | RFC 9562 compliant, immutable, minimal allocations | ⭐⭐⭐⭐⭐ |
| SecureRandom | v4, v7 | Zero (stdlib) | Simple string generation | ⭐⭐⭐ |
| uuidtools | v1, v3, v4, v5 | uuidtools gem | Full-featured, parsing | ⭐⭐ |
| ruby-uuid | v1, v3, v4, v5 | ruby-uuid gem | C extension, fast | ⭐⭐⭐⭐ |
| guid | v4 only | guid gem | Simple, Rails-focused | ⭐ |

## Detailed Comparison

### fast-uuid vs SecureRandom

**SecureRandom** is Ruby's standard library module for secure random number generation, including UUIDs.

#### What SecureRandom Provides

```ruby
# v4 UUID as string
SecureRandom.uuid_v4  # => "919108f7-52d1-4320-9bac-f847db4148a8"

# v7 UUID as string (Ruby 3.2+)
SecureRandom.uuid_v7  # => "018e312f-4b1e-7000-8000-000000000000"
```

#### Comparison

| Feature | fast-uuid | SecureRandom |
|---------|-----------|--------------|
| **Versions** | v1, v3, v4, v5, v6, v7 | v4, v7 only |
| **Return type** | Value object or String | String only |
| **Parsing** | Yes (full RFC 9562) | No |
| **Validation** | Yes | No |
| **Timestamp extraction** | Yes (v1, v6, v7) | No |
| **Comparison** | Yes (full Comparable) | No (strings only) |
| **v4 speed** | ~12% faster | Baseline |
| **v7 speed** | On par (within error) | Baseline |
| **Allocations (v4)** | 2 (string) / 4 (object) | 8 (string) |
| **Allocations (v7)** | 4 (string) / 6 (object) | 10 (string) |
| **Dependencies** | Zero | Zero (stdlib) |
| **RFC 9562 compliance** | Full | Partial |

#### When to Use SecureRandom

- You only need v4 or v7 UUIDs as strings
- You're already using SecureRandom for other purposes
- You want the absolute minimum gem count (SecureRandom is in stdlib)
- You don't need parsing, validation, or value objects

#### When to Use fast-uuid

- You need any UUID version beyond v4/v7
- You need parsing or validation
- You need value objects with comparison, timestamps, etc.
- You want better performance
- You want a richer API

#### Migration from SecureRandom

fast-uuid is a **drop-in replacement** for SecureRandom's UUID methods:

```ruby
# Before (SecureRandom)
SecureRandom.uuid_v4
SecureRandom.uuid_v7

# After (fast-uuid)
Fast::UUID.uuid_v4
Fast::UUID.uuid_v7
```

No other code changes are needed for basic string generation.

### fast-uuid vs UUIDTools

**UUIDTools** is a popular Ruby gem for UUID generation and parsing.

#### What UUIDTools Provides

```ruby
# Generation
UUIDTools::UUID.random_create  # v4
UUIDTools::UUID.timestamp_create  # v1
UUIDTools::UUID.sha1_create(namespace, name)  # v5
UUIDTools::UUID.md5_create(namespace, name)  # v3

# Parsing
UUIDTools::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")

# Validation
UUIDTools::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
```

#### Comparison

| Feature | fast-uuid | UUIDTools |
|---------|-----------|-----------|
| **Versions** | v1, v3, v4, v5, v6, v7 | v1, v3, v4, v5 |
| **v7 support** | Yes | No |
| **Return type** | Value object or String | UUIDTools::UUID object |
| **Parsing speed** | ~2.7x faster | Baseline |
| **Parsing allocations** | 6 objects | 27 objects |
| **Generation speed** | Faster | Slower |
| **Dependencies** | Zero | uuidtools gem |
| **RFC 9562 compliance** | Full | Good |
| **API style** | Modern Ruby | Older style |
| **Maintenance** | Active | Less active |

#### When to Use UUIDTools

- You're already using UUIDTools in your codebase
- You need features specific to UUIDTools (like UUID version conversion)
- You don't need v6 or v7 support

#### When to Use fast-uuid

- You want better performance (especially for parsing)
- You want zero dependencies
- You need v6 or v7 support
- You prefer a modern Ruby API
- You want immutable value objects

#### Migration from UUIDTools

```ruby
# Before (UUIDTools)
uuid = UUIDTools::UUID.random_create
uuid = UUIDTools::UUID.timestamp_create
uuid = UUIDTools::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")

# After (fast-uuid)
uuid = Fast::UUID.v4
uuid = Fast::UUID.v1
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
```

### fast-uuid vs ruby-uuid

**ruby-uuid** is a C extension gem for UUID generation.

#### What ruby-uuid Provides

```ruby
# Generation
UUID.new  # v4
UUID.timestamp  # v1
UUID.v3(namespace, name)
UUID.v5(namespace, name)

# Parsing
UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
```

#### Comparison

| Feature | fast-uuid | ruby-uuid |
|---------|-----------|-----------|
| **Implementation** | Pure Ruby | C extension |
| **Versions** | v1, v3, v4, v5, v6, v7 | v1, v3, v4, v5 |
| **v7 support** | Yes | No |
| **v6 support** | Yes | No |
| **Dependencies** | Zero | ruby-uuid gem (C extension) |
| **Installation** | Simple | Requires C compiler |
| **Portability** | Any Ruby | Limited (C extension) |
| **Performance** | Very fast | Faster (C) |
| **Parsing** | Yes | Yes |
| **Value objects** | Yes (immutable) | Yes |

#### When to Use ruby-uuid

- You need absolute maximum performance
- You're comfortable with C extensions
- You don't need v6 or v7
- You're on a platform with a C compiler

#### When to Use fast-uuid

- You want pure Ruby (no C extensions)
- You need v6 or v7 support
- You want zero external dependencies
- You want better portability
- You prefer the performance to be "fast enough" (fast-uuid is still very fast)

### fast-uuid vs guid

**guid** is a simple UUID v4 generator for Rails.

#### What guid Provides

```ruby
# Generation
Guid.new  # v4 as string
Guid.raw  # v4 as raw bytes
```

#### Comparison

| Feature | fast-uuid | guid |
|---------|-----------|------|
| **Versions** | v1, v3, v4, v5, v6, v7 | v4 only |
| **Return type** | Value object or String | String only |
| **Parsing** | Yes | No |
| **Dependencies** | Zero | guid gem |
| **Rails integration** | No | Yes |
| **Performance** | Faster | Slower |

#### When to Use guid

- You're using Rails and want Rails integration
- You only need v4 UUIDs
- You want a simple, Rails-focused API

#### When to Use fast-uuid

- You need any UUID version beyond v4
- You need parsing or validation
- You want better performance
- You're not using Rails or don't need Rails integration

## Feature Matrix

| Feature | fast-uuid | SecureRandom | UUIDTools | ruby-uuid | guid |
|---------|-----------|--------------|-----------|-----------|------|
| v1 generation | ✅ | ❌ | ✅ | ✅ | ❌ |
| v3 generation | ✅ | ❌ | ✅ | ✅ | ❌ |
| v4 generation | ✅ | ✅ | ✅ | ✅ | ✅ |
| v5 generation | ✅ | ❌ | ✅ | ✅ | ❌ |
| v6 generation | ✅ | ❌ | ❌ | ❌ | ❌ |
| v7 generation | ✅ | ✅ | ❌ | ❌ | ❌ |
| Parsing | ✅ | ❌ | ✅ | ✅ | ❌ |
| Validation | ✅ | ❌ | ✅ | ✅ | ❌ |
| Timestamp extraction | ✅ | ❌ | ❌ | ❌ | ❌ |
| Value objects | ✅ | ❌ | ✅ | ✅ | ❌ |
| Immutable | ✅ | N/A | ❌ | ✅ | N/A |
| Comparable | ✅ | N/A | ❌ | ✅ | N/A |
| Zero dependencies | ✅ | ✅ (stdlib) | ❌ | ❌ | ❌ |
| Pure Ruby | ✅ | ✅ | ✅ | ❌ | ✅ |
| RFC 9562 compliant | ✅ | Partial | ✅ | ✅ | ❌ |

## Performance Comparison

Based on the benchmark script included with fast-uuid (measured on Ruby 4.0.7,
arm64-darwin23; absolute numbers vary by machine — rerun it on your own
hardware):

### String Generation (v4)

```
| Library | i/s | Allocations |
|--------|-----|-------------|
| fast-uuid.uuid_v4 | ~777,000 | 2 |
| SecureRandom.uuid_v4 | ~696,000 | 8 |
```

**fast-uuid is ~12% faster with 4x fewer allocations**

### String Generation (v7)

```
| Library | i/s | Allocations |
|--------|-----|-------------|
| fast-uuid.uuid_v7 | ~696,000 | 4 |
| SecureRandom.uuid_v7 | ~706,000 | 10 |
```

**fast-uuid matches SecureRandom throughput (within the ~4% error margin) with 2.5x fewer allocations**

### Parsing

```
| Library | i/s | Allocations |
|--------|-----|-------------|
| fast-uuid.parse | ~1,250,000 | 6 |
| UUIDTools::UUID.parse | ~455,000 | 27 |
```

**fast-uuid is ~2.7x faster with ~4.5x fewer allocations**

### Value Object Generation (v7)

```
| Library | i/s | Allocations |
|--------|-----|-------------|
| fast-uuid.v7 | ~636,000 | 6 |
```

**fast-uuid value objects stay within ~10% of the plain-String paths**

## Recommendations

### Use fast-uuid if you:

- Need **any UUID version** (v1, v3, v4, v5, v6, v7)
- Need **parsing or validation**
- Need **value objects** with comparison, timestamps, etc.
- Want **zero dependencies**
- Want **pure Ruby** (no C extensions)
- Want **better performance** than most alternatives
- Need **RFC 9562 compliance**
- Need **immutable, frozen objects**

### Use SecureRandom if you:

- Only need **v4 or v7 as strings**
- Want **zero external gems** (SecureRandom is in stdlib)
- Don't need parsing, validation, or value objects
- Are okay with **slightly slower** performance

### Use UUIDTools if you:

- Are **already using it** in your codebase
- Need features **specific to UUIDTools**
- Don't need **v6 or v7**
- Don't mind **slower parsing**

### Use ruby-uuid if you:

- Need **absolute maximum performance**
- Are okay with **C extensions**
- Don't need **v6 or v7**
- Have a **C compiler** available

### Use guid if you:

- Are using **Rails**
- Only need **v4 UUIDs**
- Want **Rails integration**

## Migration Guide

### From SecureRandom

```ruby
# Before
SecureRandom.uuid_v4
SecureRandom.uuid_v7

# After
Fast::UUID.uuid_v4
Fast::UUID.uuid_v7
```

No other changes needed for basic usage.

### From UUIDTools

```ruby
# Before
UUIDTools::UUID.random_create
UUIDTools::UUID.timestamp_create
UUIDTools::UUID.parse(str)
UUIDTools::UUID.valid?(str)

# After
Fast::UUID.v4
Fast::UUID.v1
Fast::UUID.parse(str)
Fast::UUID.valid?(str)
```

### From ruby-uuid

```ruby
# Before
UUID.new
UUID.timestamp
UUID.parse(str)

# After
Fast::UUID.v4
Fast::UUID.v1
Fast::UUID.parse(str)
```

### From guid

```ruby
# Before
Guid.new

# After
Fast::UUID.uuid_v4
# or
Fast::UUID.v4.to_s
```

## Summary

| Use Case | Recommended Library |
|----------|---------------------|
| General purpose UUIDs | **fast-uuid** |
| Simple v4/v7 strings | SecureRandom |
| Legacy code using UUIDTools | fast-uuid (migrate) |
| Maximum performance, C okay | ruby-uuid |
| Rails v4 UUIDs | guid or fast-uuid |
| Full RFC 9562 compliance | **fast-uuid** |
| Zero dependencies | **fast-uuid** or SecureRandom |
| Pure Ruby | **fast-uuid** or SecureRandom |

**fast-uuid is the best choice for most use cases** — it provides the most features, best performance (for pure Ruby), zero dependencies, and full RFC 9562 compliance.
