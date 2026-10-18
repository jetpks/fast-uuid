# fast-uuid

RFC 9562 UUIDs for Ruby: generate v4/v7, parse every version, compare, no dependencies.

## What it is

`fast-uuid` is a zero-dependency Ruby gem that provides **high-performance UUID generation and parsing** fully compliant with [RFC 9562](https://www.rfc-editor.org/rfc/rfc9562). It generates all standard UUID versions (v1, v3, v4, v5, v6, v7), parses and validates any RFC 9562 canonical form, and provides an immutable value object with full comparison support.

## Why it exists

- **Performance**: Designed for minimal allocations and maximum speed — benchmarked against `securerandom` and `uuidtools`
- **Completeness**: Supports all RFC 9562 versions, including the recommended v7 (Unix Epoch-based)
- **Zero dependencies**: Only requires Ruby's standard library (digest, securerandom)
- **Precision**: v1/v6 use 100-ns Gregorian timestamps; v7 uses millisecond Unix timestamps
- **Sortability**: v6 and v7 sort chronologically as raw bytes

## Installation

```ruby
gem install fast-uuid
```

Or add to your Gemfile:

```ruby
gem "fast-uuid", "~> 0.1.0"
```

## Quick start

```ruby
require "fast/uuid"

# Generate a v7 UUID (RFC-recommended default) as a value object
uuid = Fast::UUID.v7
uuid.to_s           # => "018e312f-4b1e-7000-8000-000000000000"
uuid.version        # => 7
uuid.variant        # => :rfc9562
uuid.timestamp      # => 2024-01-15 10:30:00 UTC

# Generate as a String directly (drop-in for SecureRandom.uuid_v7)
Fast::UUID.uuid_v7  # => "018e312f-4b1e-7000-8000-000000000000"

# Parse a UUID string
parsed = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
parsed.version       # => 7
parsed == uuid      # => false (different values)

# Generate other versions
Fast::UUID.v4        # Random UUID, version 4
Fast::UUID.v1        # Time-based with random node
Fast::UUID.v6        # Time-based, chronologically sortable
Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "example.com")  # MD5-based
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "example.com")  # SHA-1-based

# Validate
Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")  # => true
Fast::UUID.valid?("not-a-uuid")                            # => false
```

## Documentation

| Purpose | Location |
|---|---|
| **Get started** | [Tutorials](docs/tutorials/) |
| **Solve a task** | [How-to Guides](docs/how-to-guides/) |
| **API reference** | [Reference](docs/reference/) |
| **Understand the design** | [Explanation](docs/explanation/) |

### Tutorials

- [Getting Started with fast-uuid](docs/tutorials/getting-started.md) — Generate, parse, and work with UUIDs

### How-to Guides

- [Generate UUIDs](docs/how-to-guides/generating-uuids.md) — All version generation options
- [Parse and Validate UUIDs](docs/how-to-guides/parsing-and-validating.md) — Input handling and validation
- [Work with Timestamps](docs/how-to-guides/timestamps.md) — Extract and use timestamps from time-based UUIDs
- [Handle Errors](docs/how-to-guides/error-handling.md) — Error types and recovery patterns
- [Use Name-based UUIDs](docs/how-to-guides/name-based-uuids.md) — v3 and v5 with namespaces

### Reference

- [API Reference](docs/reference/api.md) — Complete public API documentation

### Explanation

- [Design Philosophy](docs/explanation/design.md) — Why fast-uuid is structured this way
- [Performance](docs/explanation/performance.md) — How fast-uuid achieves its speed
- [Comparison with Alternatives](docs/explanation/comparison.md) — fast-uuid vs securerandom, uuidtools, and others

## Requirements

- Ruby >= 3.3

## Links

- [Source Code](https://github.com/jetpks/fast-uuid)
- [Issues](https://github.com/jetpks/fast-uuid/issues)
- [Changelog](https://github.com/jetpks/fast-uuid/blob/main/CHANGELOG.md)

## License

MIT License. See the [LICENSE](LICENSE) file for details.
