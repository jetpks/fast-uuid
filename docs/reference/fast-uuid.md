# Fast::UUID — API reference

`require "fast/uuid"` — Ruby `>= 3.3`. `Fast` is a module containing the class `Fast::UUID`, which includes `Comparable`.

## Class methods — generation

### `.v4`

```ruby
Fast::UUID.v4() -> Fast::UUID
```

128 CSPRNG bits via `SecureRandom.bytes(16)`, 122 stay random, version 4 and `10xx` variant stamped in place. Frozen instance.

### `.uuid_v4`

```ruby
Fast::UUID.uuid_v4() -> String  # frozen canonical
```

Same 128 random bits as `.v4`, rendered straight to the canonical form. Drop-in for `SecureRandom.uuid_v4`; the value object is skipped.

### `.v7`

```ruby
Fast::UUID.v7(time: Time.now) -> Fast::UUID
```

48-bit `unix_ts_ms` truncated to whole milliseconds + fully random `rand_a`/`rand_b` (74 random bits total), no counter and no shared state. Version 7 and `10xx` variant stamped. Frozen instance.

```ruby
Fast::UUID.v7(time: Time.utc(2022, 2, 22, 19, 22, 22))
```

### `.uuid_v7`

```ruby
Fast::UUID.uuid_v7(time: Time.now) -> String  # frozen canonical
```

Same 48-bit `unix_ts_ms` and random tail as `.v7`, rendered straight to the canonical form. Drop-in for `SecureRandom.uuid_v7`.

### `.v1`

```ruby
Fast::UUID.v1(time: Time.now, node: nil, clock_sequence: nil) -> Fast::UUID
```

60-bit 100-ns Gregorian ticks, `time_low` first on the wire. 14-bit `clock_seq` over a 48-bit node, version 1 and `10xx` variant stamped. `node` and `clock_sequence` follow `node_id` / `sequence_low` rules below. Frozen instance. Prefer v7 per RFC 9562 Section 5.7; v1 does not sort chronologically.

### `.uuid_v1`

```ruby
Fast::UUID.uuid_v1(time: Time.now, node: nil, clock_sequence: nil) -> String  # frozen canonical
```

Same 60-bit timestamp as `.v1`, rendered straight to the canonical form with the same `node` and `clock_sequence` handling.

### `.v6`

```ruby
Fast::UUID.v6(time: Time.now, node: nil, clock_sequence: nil) -> Fast::UUID
```

v1's fields reordered most-significant-first (RFC 9562 Section 5.6, the v1 migration version): `time_high`, then `time_mid`, then `time_low` under version nibble 6. Same node, clock sequence, and variant as v1. Sorts chronologically as raw bytes where v1 does not. Frozen instance.

### `.uuid_v6`

```ruby
Fast::UUID.uuid_v6(time: Time.now, node: nil, clock_sequence: nil) -> String  # frozen canonical
```

Same reordered timestamp as `.v6`, rendered straight to the canonical form.

### `.v3`

```ruby
Fast::UUID.v3(namespace, name) -> Fast::UUID
```

MD5 over `namespace.bytes + name.b`, whole 128-bit digest, version 3 and `10xx` variant stamped. `namespace` may be a `Fast::UUID` or any String that parses as a UUID. `name` is its String form (`to_s` / Symbol `name`). Frozen instance. Prefer v5.

### `.uuid_v3`

```ruby
Fast::UUID.uuid_v3(namespace, name) -> String  # frozen canonical
```

Same MD5 digest as `.v3`, rendered straight to the canonical form.

### `.v5`

```ruby
Fast::UUID.v5(namespace, name) -> Fast::UUID
```

SHA-1 leftmost 128 of 160 bits (rightmost 32 discarded), version 5 and `10xx` variant stamped. Same `namespace`/`name` input handling as `.v3`. Frozen instance.

### `.uuid_v5`

```ruby
Fast::UUID.uuid_v5(namespace, name) -> String  # frozen canonical
```

Same SHA-1 digest as `.v5`, rendered straight to the canonical form.

### `.generate`

```ruby
Fast::UUID.generate() -> Fast::UUID
```

The RFC's recommended default: v7. Equivalent to `v7` with no arguments.

### `.uuid`

```ruby
Fast::UUID.uuid() -> String  # frozen canonical
```

The RFC's recommended default as a String: the v7 canonical form. Equivalent to `uuid_v7` with no arguments.

## Class methods — helpers

Public plumbing for v1/v6 field construction. They are public API.

### `.gregorian_ticks`

```ruby
Fast::UUID.gregorian_ticks(time) -> Integer  # 60-bit ticks
```

`(time.to_i * 10_000_000) + (time.nsec / 100) + GREGORIAN_OFFSET`, masked to 60 bits. 100-ns ticks between the Gregorian epoch (1582-10-15) and the given `time`.

### `.node_id`

```ruby
Fast::UUID.node_id(node) -> Integer  # 48-bit node
```

- `nil` → fresh CSPRNG value with the multicast bit set (RFC 9562 Section 6.10): `SecureRandom.bytes(6).unpack1("H12").to_i(16) | (1 << 40)`.
- `Integer` → masked to 48 bits: `node & 0xFFFFFFFFFFFF`.
- `String` (6 bytes) → unpacked from its 6 binary bytes: `node.b.unpack1("H12").to_i(16)`. Wrong size raises `TypeError`.
- `Symbol` → via `node.name`, the frozen String it already carries.
- `to_int` carrier → `node.to_int & 0xFFFFFFFFFFFF`.
- `to_s` carrier → `node_id(node.to_s)` (recurses; `nil` and String cases re-evaluated).
- Else → `TypeError` (`an Integer-like or 6-byte string-like node is required`).

### `.sequence_low`

```ruby
Fast::UUID.sequence_low(node, clock_sequence) -> Integer  # low word
```

14-bit `clock_seq` over the 48-bit node, variant's top two bits stamped in place after the pack.

- `clock_sequence` as `Integer` → masked to 14 bits.
- `nil` → fresh CSPRNG: `SecureRandom.bytes(2).unpack1("n") & 0x3FFF`.
- `to_int` carrier → `clock_sequence.to_int` then masked.
- No `to_int` → `TypeError` (`an Integer-like clock_sequence is required`).

Returns `((clock_sequence & 0x3FFF) << 48) | node_id(node)` before the pack stamps `0x80` into byte 8.

## Class methods — parsing

The canonical grammar:

```ruby
Fast::UUID::CANONICAL
# => /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
```

Validity is this grammar and nothing more: the RFC defines no version or variant gate, and Nil and Max sit outside the `10xx` variant by design. Case-insensitive. Every version (0–15) and variant parses, Nil and Max included.

### `.parse`

```ruby
Fast::UUID.parse(str) -> Fast::UUID
```

Grammar-only validation against `CANONICAL`. Accepts String, Symbol (via `#name`), or any object responding to `#to_s`. Converts with `implicit_string` (Symbol's frozen `#name` avoids a copy). Non-conforming String raises `Fast::UUID::ParseError` naming the input: `"not a valid UUID: #{str}"`. An object with no `to_s` raises `TypeError: "no implicit conversion into Fast::UUID"`.

### `.parse?`

```ruby
Fast::UUID.parse?(str) -> Fast::UUID or nil
```

`parse`, rescuing `TypeError` and `ParseError` to `nil`.

### `.valid?`

```ruby
Fast::UUID.valid?(str) -> true or false
```

`CANONICAL.match?` over the implicit String. `TypeError` (no `to_s`) answers `false`.

## Instance methods

All are arity 0 unless noted. `Comparable` included; `<=>` defines ordering.

### `#initialize`

```ruby
Fast::UUID.new(bytes) -> Fast::UUID  # frozen
```

From a 16-byte binary `String`, or anything carrying one via `#to_str` (the implicit String protocol). Encoding tag on the input is normalized to binary via `.b`. Wrong `bytesize` raises `ArgumentError: "a 16-byte binary String is required (got #{bytes.bytesize} bytes)"`. No `to_str` or classless object (e.g. `BasicObject` descendant) raises `ArgumentError: "a 16-byte binary String is required (got #{klass})"`. Freezes `bytes` and the instance; `to_s` is precomputed and frozen at construction.

```ruby
Fast::UUID.new(Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f").bytes)
```

### `#version`

```ruby
uuid.version -> Integer  # 0-15
```

Byte 6 high nibble: `@bytes.getbyte(6) >> 4`.

### `#variant`

```ruby
uuid.variant -> :rfc9562 or :microsoft or :future or :ncs
```

Byte 8 top two bits: `10xx` → `:rfc9562`, `110x` → `:microsoft`, `111x` → `:future`, else (`0xxx`) → `:ncs`.

### `#timestamp`

```ruby
uuid.timestamp -> Time (UTC) or nil
```

- v1: 60-bit 100-ns Gregorian timestamp reconstructed from `time_low`/`time_mid`/`time_hi_and_version` on the wire, as UTC `Time`.
- v6: same 60-bit ticks, fields in descending significance (`time_high`/`time_mid`/`time_low`).
- v7: `unix_ts_ms` at millisecond resolution, as UTC `Time`: `Time.at(milliseconds / 1000, (milliseconds % 1000) * 1_000_000, :nanosecond).utc`.
- Every other version (0, 2, 3, 4, 5, 8, 15): `nil`.

### `#bytes`

```ruby
uuid.bytes -> String  # frozen binary, 16 bytes
```

`attr_reader` over the frozen copy set at construction.

### `#to_s`

```ruby
uuid.to_s -> String  # frozen lowercase canonical, 36 chars, 8-4-4-4-12
```

Precomputed at construction: `Digest.hexencode(@bytes).insert(8, "-").insert(13, "-").insert(18, "-").insert(23, "-").freeze`.

### `#to_str`

```ruby
uuid.to_str -> String  # alias of to_s
```

String-protocol participation: `alias to_str to_s`. Allows `String.new.concat("x", uuid)`, `"x#{uuid}"` (via `to_s`), and `Array#join`.

### `#hex`

```ruby
uuid.hex -> String  # 32 lowercase hex chars, no hyphens
```

`Digest.hexencode(@bytes)`. Allocates 1 object.

### `#urn`

```ruby
uuid.urn -> String  # "urn:uuid:#{canonical}"
```

`"urn:uuid:#{@string}"`. Allocates 1 object.

### `#nil_uuid?`

```ruby
uuid.nil_uuid? -> true or false
```

`self == NIL`.

### `#max_uuid?`

```ruby
uuid.max_uuid? -> true or false
```

`self == MAX`.

### `#==`

```ruby
uuid == other -> true or false
```

True only for another `Fast::UUID` with identical 16 bytes: `other.is_a?(UUID) && other.bytes == bytes`. Provenance irrelevant. A UUID never equals its String.

### `#eql?`

```ruby
uuid.eql?(other) -> true or false
```

Alias of `==`.

### `#hash`

```ruby
uuid.hash -> Integer
```

`bytes.hash`. Safe as `Hash`/`Set` key.

### `#<=>`

```ruby
uuid <=> other -> -1 or 0 or 1 or nil
```

Opaque unsigned 128-bit byte order: `bytes <=> other.bytes` if `other.is_a?(UUID)`, else `nil`. `Comparable` included. v6 and v7 sort chronologically as raw bytes; v1 does not, its `time_low` sits first.

## Constants

| Constant | Value | Notes |
|---|---|---|
| `Fast::UUID::CANONICAL` | `/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i` | Case-insensitive canonical grammar |
| `Fast::UUID::GREGORIAN_OFFSET` | `122_192_928_000_000_000` | 100-ns ticks, Gregorian 1582-10-15 to Unix epoch |
| `Fast::UUID::NIL` | `Fast::UUID.new(("\0" * 16).b)` | All-zero UUID, frozen |
| `Fast::UUID::MAX` | `Fast::UUID.new(("\xFF" * 16).b)` | All-`FF` UUID, frozen |
| `Fast::UUID::NAMESPACE_DNS` | `6ba7b810-9dad-11d1-80b4-00c04fd430c8` | RFC 9562 DNS namespace |
| `Fast::UUID::NAMESPACE_URL` | `6ba7b811-9dad-11d1-80b4-00c04fd430c8` | RFC 9562 URL namespace |
| `Fast::UUID::NAMESPACE_OID` | `6ba7b812-9dad-11d1-80b4-00c04fd430c8` | RFC 9562 OID namespace |
| `Fast::UUID::NAMESPACE_X500` | `6ba7b814-9dad-11d1-80b4-00c04fd430c8` | RFC 9562 X.500 namespace |
| `Fast::UUID::VERSION` | `"0.1.0"` | Gem version |

`NIL` is version 0 / `:ncs`; `MAX` is version 15 / `:future`. Both are valid per the grammar-only rule.

## Errors

```ruby
Fast::UUID::Error < StandardError
Fast::UUID::ParseError < Fast::UUID::Error  # "a String that is not a UUID in the RFC 9562 canonical form"
```

`ParseError` is raised by `.parse` with message `"not a valid UUID: #{str}"`. Both are defined in `lib/fast/uuid/errors.rb`.

## Private helpers, not API

`digest_input`, `v4_bytes`, `v7_bytes`, `v1_bytes`, `v6_bytes`, `v3_bytes`, `v5_bytes`, `stamp`, `canonical`, and `implicit_string` are `private_class_method`s — load-bearing internals shared by the object constructors and their `uuid_*` String twins, not contract. Do not call them.

## Compatibility & installation

- Gem name: `fast-uuid`.
- No runtime dependencies. stdlib `digest` and `securerandom` only.
- Ruby `>= 3.3`.
- Dev dependencies from `gems.rb`: `sus`, `covered`, `rubocop` (test group); `uuidtools` (test, reference parser for benchmarks); `benchmark-ips` (benchmark group). None are runtime dependencies.

```sh
gem install fast-uuid
```

```ruby
gem "fast-uuid"
require "fast/uuid"
```
