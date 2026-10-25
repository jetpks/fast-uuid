# Choose a UUID version

## The short version

For new identifiers, use v7 (`Fast::UUID.generate`) — the RFC's recommended default, sorts chronologically. For a purely random identifier, use v4 (`Fast::UUID.v4`).

```ruby
require "fast/uuid"

id = Fast::UUID.generate # => v7
random = Fast::UUID.v4   # => purely random
```

## The decision table

| Choice | Method | When to use |
|---|---|---|
| v4 | `Fast::UUID.v4` | 122 random bits. Purely random identifier, no timestamp. |
| v7 | `Fast::UUID.v7` / `Fast::UUID.generate` | 48-bit `unix_ts_ms` + 74-bit random tail, sortable. The default for new columns. |
| v1 | `Fast::UUID.v1` | Legacy 60-bit 100-ns Gregorian timestamp. Does not sort chronologically. |
| v6 | `Fast::UUID.v6` | Same 60-bit fields as v1, reordered to sort chronologically. |
| v3 | `Fast::UUID.v3` | MD5 name-based, deterministic from namespace + name. |
| v5 | `Fast::UUID.v5` | SHA-1 name-based, deterministic from namespace + name. Prefer over v3. |

String twins exist for every constructor: `uuid_v4`, `uuid_v7`, `uuid_v1`, `uuid_v6`, `uuid_v3`, `uuid_v5`, and `uuid` (alias for `uuid_v7`). They render directly to a frozen canonical String — see [Replace SecureRandom UUID generation with fast-uuid](replace-securerandom.md).

```ruby
Fast::UUID.uuid_v4  # => String
Fast::UUID.uuid_v7  # => String
Fast::UUID.uuid     # => String (v7)
```

## Time-ordered: v7, or v6 if you must

Prefer v7 over v1 and v6 per RFC 9562 Section 5.7.

- v7 truncates time to whole milliseconds (`unix_ts_ms`). Sub-millisecond precision is truncated:

  ```ruby
  time = Time.utc(2022, 2, 22, 19, 22, 22)
  Fast::UUID.v7(time: time + 0.000999).timestamp == time # => true (truncated)
  Fast::UUID.v7(time: time + Rational(1, 1000)).timestamp == time + Rational(1, 1000) # => true
  ```

- v1 and v6 keep 100-ns Gregorian ticks and carry the extra resolution:

  ```ruby
  sub_second = Time.at(time.to_i, 123_456_700, :nanosecond)
  Fast::UUID.v1(time: sub_second).timestamp == sub_second # => true
  Fast::UUID.v6(time: sub_second).timestamp == sub_second # => true
  ```

- Only v6 and v7 sort chronologically as raw bytes. v1 does not — its `time_low` field sits first on the wire. See [How the versions and variants are laid out](../explanation/version-variant-layout.md) for the field order.

```ruby
time = Time.utc(2022, 2, 22, 19, 22, 22)
Fast::UUID.v7(time: time) < Fast::UUID.v7(time: time + 1) # => true
Fast::UUID.v6(time: time) < Fast::UUID.v6(time: time + 1) # => true
```

## Deterministic from a name: v5, or v3 for legacy

Prefer v5 (SHA-1, leftmost 128 bits of the 160-bit digest) over v3 (MD5, whole 128-bit digest). Both digest the namespace's 16 bytes followed by the name's bytes, then stamp the version and 10xx variant.

See [Generate deterministic v3 and v5 UUIDs from names](name-based-uuids.md) for namespace selection, known vectors, and `to_s` semantics.

## The rest of the surface

The class also parses and validates every version and exposes the fields — see [Fast::UUID — API reference](../reference/fast-uuid.md) and [Validate and parse UUID strings from user input](validate-user-input.md).
