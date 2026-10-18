# Design Philosophy

This document explains the design decisions behind the fast-uuid gem and how they contribute to its performance, correctness, and usability.

## Core Principles

### RFC 9562 Compliance

fast-uuid is designed to be **fully compliant** with [RFC 9562](https://www.rfc-editor.org/rfc/rfc9562) (formerly RFC 4122). This means:

1. **All versions supported**: v1, v3, v4, v5, v6, v7 are all generatable
2. **All variants parseable**: NCS, RFC 9562, Microsoft, and Future variants are all recognized
3. **Canonical format**: UUIDs are always rendered in the RFC-specified 8-4-4-4-12 lowercase hex format
4. **Test vectors**: All RFC 9562 Appendix A test vectors are correctly generated and parsed

The gem deliberately does **not** enforce version or variant constraints during parsing. According to RFC 9562, the canonical form is defined purely by the string grammar (32 hex digits with hyphens in specific positions), not by the version or variant bits. This means:

```ruby
# These are all valid according to RFC 9562
Fast::UUID.valid?("00000000-0000-0000-0000-000000000000")  # Nil UUID, version 0, NCS variant
Fast::UUID.valid?("ffffffff-ffff-ffff-ffff-ffffffffffff")  # Max UUID, version 15, Future variant
```

### Zero Dependencies

fast-uuid has **no runtime dependencies** beyond Ruby's standard library. It requires:
- `digest` — For MD5 (v3) and SHA-1 (v5) hashing
- `securerandom` — For CSPRNG access (v4, v7, and default node/clock values)

This makes the gem:
- Easy to install and use
- Compatible with any Ruby environment
- Suitable for constrained environments
- Free from dependency conflicts

### Immutability

All `Fast::UUID` instances are **frozen** (immutable):

```ruby
uuid = Fast::UUID.v7
uuid.frozen?  # => true
```

This design choice provides several benefits:

1. **Thread safety**: Immutable objects can be safely shared across threads without synchronization
2. **Hash key stability**: UUIDs can be used as hash keys without worrying about mutation
3. **Predictability**: Once created, a UUID's value never changes
4. **Memory efficiency**: Frozen strings can be deduplicated by Ruby's garbage collector

The immutability extends to all string representations:

```ruby
uuid = Fast::UUID.v7
uuid.to_s.frozen?    # => true
uuid.hex.frozen?     # => false (computed on demand)
uuid.urn.frozen?     # => false (computed on demand)
uuid.bytes.frozen?   # => true
```

### Dual API: Value Objects and Strings

fast-uuid provides **two parallel APIs** for each generation method:

1. **Value object methods** (`v4`, `v7`, `v1`, etc.) — Return `Fast::UUID` instances
2. **String methods** (`uuid_v4`, `uuid_v7`, `uuid_v1`, etc.) — Return frozen canonical strings

This dual approach serves different use cases:

```ruby
# When you need the full UUID functionality
uuid = Fast::UUID.v7
uuid.version    # => 7
uuid.timestamp  # => 2024-01-15 10:30:00 UTC
uuid == other   # => true/false

# When you just need a string (drop-in replacement for SecureRandom)
string = Fast::UUID.uuid_v7
# Use string directly, no object overhead
```

The string methods are **drop-in replacements** for `SecureRandom.uuid_v4` and `SecureRandom.uuid_v7`:

```ruby
# These are equivalent
SecureRandom.uuid_v4
Fast::UUID.uuid_v4

SecureRandom.uuid_v7
Fast::UUID.uuid_v7
```

### Minimal Allocations

Performance is a primary goal of fast-uuid. The gem is designed to minimize object allocations in hot paths:

| Operation | Allocations |
|-----------|-------------|
| `parse` | ~6 objects |
| `v4` | ~4 objects |
| `v7` | ~6 objects |
| `uuid_v4` | ~2 objects |
| `uuid_v7` | ~4 objects |
| `v1` | ~9-13 objects |
| `v6` | ~9 objects |
| `v3` | ~8 objects |
| `v5` | ~9 objects |
| `to_s` | ~0 objects (cached) |
| `hex` | ~1 object |
| `urn` | ~1 object |
| `==` | ~0 objects |
| `<=>` | ~0 objects |
| `hash` | ~0 objects |
| `timestamp` (v7) | ~2 objects |

All string representations (`to_s`, `hex`, `urn`) are **cached** on the UUID instance, so repeated calls incur no additional allocations.

### Opaque 128-bit Comparison

UUIDs are compared as **opaque unsigned 128-bit values** using raw byte comparison:

```ruby
uuid1 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 10, 0, 0))
uuid2 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 11, 0, 0))
uuid1 < uuid2  # => true (byte comparison)
```

This approach:
- Is simple and fast (direct `String#<=>` on raw bytes)
- Works consistently across all UUID versions
- Enables chronological sorting for v6 and v7 (timestamp in most significant bytes)
- Does **not** work for v1 (timestamp fields stored least-significant-first)

### RFC-Recommended Defaults

fast-uuid follows RFC 9562's recommendations:

1. **Default generation is v7**: `Fast::UUID.generate` and `Fast::UUID.uuid` both produce v7 UUIDs
2. **v7 uses Unix Epoch milliseconds**: More intuitive than Gregorian 100-ns ticks for most applications
3. **v6 for sortable time-based**: When you need time-based UUIDs that sort chronologically

## Version-Specific Design Decisions

### v4: Random UUIDs

- Uses 122 random bits from `SecureRandom.bytes(16)`
- Version nibble (4) and variant bits (10xx) stamped into place
- 122 bits remain truly random
- Simple, fast, and widely compatible

### v7: Unix Epoch-based

- Uses 48-bit Unix Epoch timestamp in milliseconds
- Provides millisecond precision (sub-millisecond values truncated)
- Timestamp stored in bytes 0-5 (most significant bytes)
- Random data in bytes 6-15
- **Sorts chronologically** as raw bytes
- RFC 9562's recommended default

The v7 implementation uses a clever byte manipulation to insert the timestamp:

```ruby
# From the source code
milliseconds = (time.to_i * 1000) + (time.nsec / 1_000_000)
milliseconds &= 0xFFFFFFFFFFFF
bytes.bytesplice(0, 6, [milliseconds].pack("Q>"), 2, 6)
```

This inserts the 48-bit milliseconds value starting at byte 0, overwriting bytes 0-5 while preserving bytes 6-7 from the random data.

### v1: Traditional Time-based

- Uses 60-bit Gregorian timestamp (100-ns ticks since 1582-10-15)
- Includes 14-bit clock sequence and 48-bit node identifier
- Timestamp fields stored least-significant-first (time_low, time_mid, time_high)
- **Does NOT sort chronologically**
- Node defaults to random with multicast bit set (RFC §6.10)
- Clock sequence defaults to random 14-bit value

### v6: Reordered Time-based

- Identical to v1 except timestamp field order
- Timestamp fields stored most-significant-first (time_high, time_mid, time_low)
- **Sorts chronologically** as raw bytes
- Same node and clock sequence handling as v1
- Provides a migration path from v1 to chronologically sortable UUIDs

### v3: MD5-based Name-based

- Uses MD5 hash of namespace bytes + name bytes
- Full 128-bit digest used
- Version and variant stamped into the digest
- Deterministic: same namespace + name = same UUID
- MD5 is cryptographically broken but may still be acceptable for non-security uses

### v5: SHA-1-based Name-based

- Uses SHA-1 hash of namespace bytes + name bytes
- Leftmost 128 bits of 160-bit digest used (rightmost 32 bits discarded)
- Version and variant stamped into the selected bits
- Deterministic: same namespace + name = same UUID
- SHA-1 is more secure than MD5

## Error Handling Design

fast-uuid uses a **minimal error hierarchy**:

```
Fast::UUID::Error
  └── Fast::UUID::ParseError
```

This design:
- Keeps the error surface small and predictable
- Uses standard Ruby errors (`TypeError`, `ArgumentError`) where appropriate
- Makes it easy to rescue all fast-uuid errors with `rescue Fast::UUID::Error`

Error messages are **descriptive and include the problematic input**:

```ruby
Fast::UUID.parse("not-a-uuid")
# => Fast::UUID::ParseError: not a valid UUID: not-a-uuid

Fast::UUID.v1(node: "short")
# => TypeError: a 6-byte node String is required (got 5 bytes)
```

## Safe Parsing

fast-uuid provides three parsing approaches with different error handling:

1. **`parse`**: Raises `ParseError` or `TypeError` on invalid input
2. **`parse?`**: Returns `nil` on invalid input (no exception)
3. **`valid?`**: Returns `true`/`false` for validity check

This gives users flexibility to choose the right approach for their use case:

```ruby
# When invalid input is an error condition
uuid = Fast::UUID.parse(input)

# When invalid input should be handled gracefully
uuid = Fast::UUID.parse?(input) || Fast::UUID.v7

# When you need to check before parsing
if Fast::UUID.valid?(input)
  uuid = Fast::UUID.parse(input)
end
```

## String-like Input Handling

fast-uuid accepts **anything string-like** for parsing and name-based generation:

```ruby
# Symbols (uses #name, which is a frozen String)
Fast::UUID.parse(:"017f22e2-79b0-7cc3-98c4-dc0c0c07398f")

# Objects with #to_s
carrier = Object.new
def carrier.to_s
  "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
end
Fast::UUID.parse(carrier)

# For names in v3/v5
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, :example_com)
```

This is implemented via the `implicit_string` helper method which:
1. Checks if the object has `#to_s` using `defined?` (works with `BasicObject` descendants)
2. For Symbols, uses `#name` directly (no copy needed, already frozen)
3. For Strings, uses as-is
4. For others with `#to_s`, calls it
5. Raises `TypeError` if no string form is available

## Node and Clock Sequence Flexibility

For v1 and v6, the node and clock sequence parameters accept multiple formats:

```ruby
# Integer (masked to 48 bits for node, 14 bits for clock)
Fast::UUID.v1(node: 0xFFFFFFFFFFFF, clock_sequence: 0x3FFF)

# String (must be exactly 6 bytes for node)
Fast::UUID.v1(node: "\x9f\x6b\xde\xce\xd8\x46")

# Symbol (uses #name as string)
Fast::UUID.v1(node: :my_node)

# Integer-like (responds to #to_int)
node_obj = Object.new
def node_obj.to_int
  0x9F6BDECED846
end
Fast::UUID.v1(node: node_obj)

# nil (generates random value)
Fast::UUID.v1(node: nil, clock_sequence: nil)
```

This flexibility is implemented via the `node_id` and `sequence_low` helper methods which use Ruby's duck typing to accept any Integer-like or String-like object.

## Summary

The fast-uuid gem's design is guided by:

1. **RFC 9562 compliance** — Correct implementation of the standard
2. **Zero dependencies** — Only uses Ruby's standard library
3. **Performance** — Minimal allocations, cached representations
4. **Immutability** — All UUIDs and their string representations are frozen
5. **Flexibility** — Dual API (value objects and strings), multiple input formats
6. **Simplicity** — Small error hierarchy, clear method names
7. **RFC recommendations** — v7 as default, Unix Epoch timestamps

These principles combine to create a gem that is fast, correct, and easy to use.
