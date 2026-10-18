# fast-uuid

fast-uuid is a pure Ruby UUID library with no dependencies.

- **Allocates half or fewer** objects per generation compared to Ruby's `SecureRandom`. [Benchmarks](docs/explanation/performance.md).
- drop-in & api-compatible with `SecureRandom`. [Migration guide](docs/how-to-guides/replace-securerandom.md).
- [RFC 9562 compliant](https://www.rfc-editor.org/info/rfc9562/)
- Covers all UUID versions: v1, v3, v4, v5, v6, and v7
- Offers immutable comparable value objects that can be used as Hash keys. See [Sort and compare](docs/how-to-guides/sort-and-compare.md)

## Installation

Install from RubyGems:

```sh
gem install fast-uuid
```

Gemfile:

```ruby
gem "fast-uuid"
```

Require path:

```ruby
require "fast/uuid"
```

The require is `fast/uuid`, not `fast-uuid`. Requires Ruby `>= 3.3`.

## Quickstart

```ruby
require "fast/uuid"

uuid = Fast::UUID.generate
uuid.to_s
# => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"  # canonical lowercase 8-4-4-4-12, 36 chars, frozen (example)

uuid.version  # => 7
uuid.variant  # => :rfc9562
uuid.timestamp # => 2022-02-22 19:22:22 UTC  # current time as UTC Time at ms resolution (example)

Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
Fast::UUID.valid?("nope") # => false

Fast::UUID::NIL < uuid && uuid < Fast::UUID::MAX # => true
```

`Fast::UUID.generate` defaults to v7, the RFC's recommended default. `to_s` is the precomputed canonical lowercase form. `timestamp` returns a UTC `Time` for v1, v6, and v7 and `nil` for other versions. `valid?` answers `true`/`false` without raising. `NIL` and `MAX` bracket every UUID in opaque byte order.

## Ordering caveat

Comparison is opaque unsigned 128-bit byte order. v6 and v7 sort chronologically as raw bytes. v1 does not — its `time_low` field sits first on the wire. See [How the versions and variants are laid out](docs/explanation/version-variant-layout.md) for the field order.

## Documentation

- Tutorial:
  - [Getting started with fast-uuid](docs/tutorials/getting-started.md)
- How-to guides:
  - [Replace SecureRandom UUID generation with fast-uuid](docs/how-to-guides/replace-securerandom.md)
  - [Choose a UUID version](docs/how-to-guides/choose-a-uuid-version.md)
  - [Validate and parse UUID strings from user input](docs/how-to-guides/validate-user-input.md)
  - [Order, compare and key UUIDs](docs/how-to-guides/sort-and-compare.md)
  - [Generate deterministic v3 and v5 UUIDs from names](docs/how-to-guides/name-based-uuids.md)
- Reference:
  - [Fast::UUID — API reference](docs/reference/fast-uuid.md)
- Explanation:
  - [Design decisions in fast-uuid](docs/explanation/design-decisions.md)
  - [How the versions and variants are laid out](docs/explanation/version-variant-layout.md)
  - [Performance and allocations](docs/explanation/performance.md)

## Compatibility

- Ruby `>= 3.3`.
- Tested on 3.3, 3.4, and 4.0 in CI.
- MIT license.
- Source and changelog at [github.com/jetpks/fast-uuid](https://github.com/jetpks/fast-uuid).

Install and compatibility details are authoritative in [`fast-uuid.gemspec`](fast-uuid.gemspec) and [`.github/workflows/ci.yml`](.github/workflows/ci.yml).
