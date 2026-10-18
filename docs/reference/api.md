# API Reference

This document describes the complete public API of the fast-uuid gem.

## Module: Fast

The top-level module containing the UUID implementation.

### Class: Fast::UUID

An immutable, frozen RFC 9562 UUID value object.

**Includes:**
- `Comparable`

**Constants:**

#### VERSION

```ruby
Fast::UUID::VERSION  # => "0.1.0"
```

The current version of the gem.

#### NIL

```ruby
Fast::UUID::NIL  # => #<Fast::UUID:0x0000... @bytes="\x00\x00...">
```

The Nil UUID (all zeros).

- `version` returns `0`
- `variant` returns `:ncs`
- `nil_uuid?` returns `true`
- `timestamp` returns `nil`

#### MAX

```ruby
Fast::UUID::MAX  # => #<Fast::UUID:0x0000... @bytes="\xFF\xFF...">
```

The Max UUID (all ones).

- `version` returns `15`
- `variant` returns `:future`
- `max_uuid?` returns `true`
- `timestamp` returns `nil`

#### NAMESPACE_DNS

```ruby
Fast::UUID::NAMESPACE_DNS  # => #<Fast::UUID:0x0000...>
```

The DNS namespace UUID (`6ba7b810-9dad-11d1-80b4-00c04fd430c8`) for use with v3 and v5.

#### NAMESPACE_URL

```ruby
Fast::UUID::NAMESPACE_URL  # => #<Fast::UUID:0x0000...>
```

The URL namespace UUID (`6ba7b811-9dad-11d1-80b4-00c04fd430c8`) for use with v3 and v5.

#### NAMESPACE_OID

```ruby
Fast::UUID::NAMESPACE_OID  # => #<Fast::UUID:0x0000...>
```

The OID namespace UUID (`6ba7b812-9dad-11d1-80b4-00c04fd430c8`) for use with v3 and v5.

#### NAMESPACE_X500

```ruby
Fast::UUID::NAMESPACE_X500  # => #<Fast::UUID:0x0000...>
```

The X.500 namespace UUID (`6ba7b814-9dad-11d1-80b4-00c04fd430c8`) for use with v3 and v5.

---

## Class Methods

### Generation Methods

#### v4

```ruby
Fast::UUID.v4 -> Fast::UUID
```

Generates a version 4 (random) UUID.

**Returns:** A new `Fast::UUID` instance with version 4 and RFC 9562 variant.

**Example:**
```ruby
uuid = Fast::UUID.v4
uuid.version  # => 4
uuid.variant  # => :rfc9562
```

#### uuid_v4

```ruby
Fast::UUID.uuid_v4 -> String
```

Generates a version 4 UUID as a canonical string.

**Returns:** A frozen String in canonical format (8-4-4-4-12 hex pattern).

**Example:**
```ruby
string = Fast::UUID.uuid_v4
# => "919108f7-52d1-4320-9bac-f847db4148a8"
```

#### v7

```ruby
Fast::UUID.v7(time: Time.now) -> Fast::UUID
```

Generates a version 7 (Unix Epoch-based) UUID.

**Parameters:**
- `time` (Time, optional) — The timestamp to use. Defaults to `Time.now`.

**Returns:** A new `Fast::UUID` instance with version 7 and RFC 9562 variant.

**Example:**
```ruby
uuid = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 10, 30, 0))
uuid.version    # => 7
uuid.variant    # => :rfc9562
uuid.timestamp  # => 2024-01-15 10:30:00 UTC
```

#### uuid_v7

```ruby
Fast::UUID.uuid_v7(time: Time.now) -> String
```

Generates a version 7 UUID as a canonical string.

**Parameters:**
- `time` (Time, optional) — The timestamp to use. Defaults to `Time.now`.

**Returns:** A frozen String in canonical format.

**Example:**
```ruby
string = Fast::UUID.uuid_v7(time: Time.utc(2024, 1, 15, 10, 30, 0))
# => "018e312f-4b1e-7000-8000-000000000000"
```

#### v1

```ruby
Fast::UUID.v1(time: Time.now, node: nil, clock_sequence: nil) -> Fast::UUID
```

Generates a version 1 (time-based, Gregorian epoch) UUID.

**Parameters:**
- `time` (Time, optional) — The timestamp to use. Defaults to `Time.now`.
- `node` (Integer, String, Symbol, nil, optional) — The 48-bit node identifier. Defaults to a random value with multicast bit set.
  - Integer: masked to 48 bits
  - String: must be exactly 6 bytes
  - Symbol: uses `#name` as string
  - nil: generates random node with multicast bit set
- `clock_sequence` (Integer, nil, optional) — The 14-bit clock sequence. Defaults to a random value.
  - Integer: masked to 14 bits
  - nil: generates random 14-bit value

**Returns:** A new `Fast::UUID` instance with version 1 and RFC 9562 variant.

**Raises:**
- `TypeError` — If node is a String but not exactly 6 bytes, or if node/clock_sequence have no Integer/String form.

**Example:**
```ruby
uuid = Fast::UUID.v1(
  time: Time.utc(2024, 1, 15, 10, 30, 0),
  node: 0x9F6BDECED846,
  clock_sequence: 0x33C8
)
uuid.version     # => 1
uuid.variant     # => :rfc9562
uuid.timestamp   # => 2024-01-15 10:30:00.000000000 UTC
```

#### uuid_v1

```ruby
Fast::UUID.uuid_v1(time: Time.now, node: nil, clock_sequence: nil) -> String
```

Generates a version 1 UUID as a canonical string.

**Parameters:** Same as `v1`.

**Returns:** A frozen String in canonical format.

**Raises:** Same as `v1`.

#### v6

```ruby
Fast::UUID.v6(time: Time.now, node: nil, clock_sequence: nil) -> Fast::UUID
```

Generates a version 6 (time-based, Gregorian epoch, reordered for sorting) UUID.

**Parameters:** Same as `v1`.

**Returns:** A new `Fast::UUID` instance with version 6 and RFC 9562 variant.

**Raises:** Same as `v1`.

**Note:** v6 sorts chronologically as raw bytes, unlike v1.

#### uuid_v6

```ruby
Fast::UUID.uuid_v6(time: Time.now, node: nil, clock_sequence: nil) -> String
```

Generates a version 6 UUID as a canonical string.

**Parameters:** Same as `v1`.

**Returns:** A frozen String in canonical format.

**Raises:** Same as `v1`.

#### v3

```ruby
Fast::UUID.v3(namespace, name) -> Fast::UUID
```

Generates a version 3 (MD5-based, name-based) UUID.

**Parameters:**
- `namespace` (Fast::UUID, String, Symbol) — The namespace UUID. Strings are parsed automatically.
- `name` (String, Symbol, Object with #to_s, Integer, nil) — The name to hash.
  - String: used as-is
  - Symbol: uses `#name`
  - Object with #to_s: uses `#to_s`
  - Integer: uses `#to_s`
  - nil: converted to empty string

**Returns:** A new `Fast::UUID` instance with version 3 and RFC 9562 variant.

**Raises:**
- `Fast::UUID::ParseError` — If namespace string is not a valid UUID.
- `TypeError` — If namespace or name has no string form.

**Example:**
```ruby
uuid = Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com")
uuid.version  # => 3
uuid.variant  # => :rfc9562
uuid.to_s     # => "5df41881-3aed-3515-88a7-2f4a814cf09e"
```

#### uuid_v3

```ruby
Fast::UUID.uuid_v3(namespace, name) -> String
```

Generates a version 3 UUID as a canonical string.

**Parameters:** Same as `v3`.

**Returns:** A frozen String in canonical format.

**Raises:** Same as `v3`.

#### v5

```ruby
Fast::UUID.v5(namespace, name) -> Fast::UUID
```

Generates a version 5 (SHA-1-based, name-based) UUID.

**Parameters:** Same as `v3`.

**Returns:** A new `Fast::UUID` instance with version 5 and RFC 9562 variant.

**Raises:** Same as `v3`.

**Example:**
```ruby
uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
uuid.version  # => 5
uuid.variant  # => :rfc9562
uuid.to_s     # => "2ed6657d-e927-568b-95e1-2665a8aea6a2"
```

#### uuid_v5

```ruby
Fast::UUID.uuid_v5(namespace, name) -> String
```

Generates a version 5 UUID as a canonical string.

**Parameters:** Same as `v3`.

**Returns:** A frozen String in canonical format.

**Raises:** Same as `v3`.

#### generate

```ruby
Fast::UUID.generate -> Fast::UUID
```

Generates a UUID using the RFC-recommended default (v7).

**Returns:** A new `Fast::UUID` instance (v7).

**Example:**
```ruby
uuid = Fast::UUID.generate
uuid.version  # => 7
```

#### uuid

```ruby
Fast::UUID.uuid -> String
```

Generates a UUID string using the RFC-recommended default (v7).

**Returns:** A frozen String in canonical format (v7).

**Example:**
```ruby
string = Fast::UUID.uuid
# => "018e312f-4b1e-7000-8000-000000000000"
```

---

### Parsing Methods

#### parse

```ruby
Fast::UUID.parse(str) -> Fast::UUID
```

Parses a canonical UUID string.

**Parameters:**
- `str` (String, Symbol, Object with #to_s) — The UUID string to parse. Case-insensitive.

**Returns:** A new `Fast::UUID` instance.

**Raises:**
- `Fast::UUID::ParseError` — If the string is not a valid RFC 9562 UUID.
- `TypeError` — If the object has no string form.

**Example:**
```ruby
uuid = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
uuid.to_s  # => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
```

#### parse?

```ruby
Fast::UUID.parse?(str) -> Fast::UUID or nil
```

Safely parses a UUID string, returning `nil` on failure.

**Parameters:** Same as `parse`.

**Returns:** A `Fast::UUID` instance, or `nil` if parsing fails.

**Example:**
```ruby
uuid = Fast::UUID.parse?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
# => #<Fast::UUID:0x0000...>

uuid = Fast::UUID.parse?("not-a-uuid")
# => nil
```

#### valid?

```ruby
Fast::UUID.valid?(str) -> true or false
```

Checks if a string is a valid RFC 9562 UUID.

**Parameters:** Same as `parse`.

**Returns:** `true` if valid, `false` otherwise.

**Note:** Only validates the string format (32 hex chars with hyphens in correct positions). Does not validate version or variant.

**Example:**
```ruby
Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")  # => true
Fast::UUID.valid?("not-a-uuid")                            # => false
Fast::UUID.valid?("00000000-0000-0000-0000-000000000000")  # => true (Nil UUID)
```

---

### Constructor

#### new

```ruby
Fast::UUID.new(bytes) -> Fast::UUID
```

Creates a UUID from raw bytes.

**Parameters:**
- `bytes` (String, Object with #to_str) — A 16-byte binary String. Objects with `#to_str` are accepted and their return value is used.

**Returns:** A new `Fast::UUID` instance.

**Raises:**
- `ArgumentError` — If bytes is not exactly 16 bytes, or if it's not a String-like object.

**Example:**
```ruby
# From 16-byte binary string
bytes = ["\x01\x7f\x22\xe2\x79\xb0\x7c\xc3\x98\xc4\xdc\x0c\x0c\x07\x39\x8f"].pack("H*")
uuid = Fast::UUID.new(bytes)

# From another UUID's bytes
other = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid = Fast::UUID.new(other.bytes)
uuid == other  # => true
```

---

## Instance Methods

### Attributes

#### bytes

```ruby
uuid.bytes -> String
```

Returns the raw 16-byte binary representation.

**Returns:** A frozen String with encoding `Encoding::BINARY`.

**Example:**
```ruby
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid.bytes.bytesize  # => 16
uuid.bytes.encoding   # => Encoding::BINARY
```

### Conversion

#### to_s

```ruby
uuid.to_s -> String
```

Returns the canonical string representation.

**Returns:** A frozen String in canonical format (lowercase, 8-4-4-4-12 hex pattern).

**Example:**
```ruby
uuid = Fast::UUID.v7
uuid.to_s  # => "018e312f-4b1e-7000-8000-000000000000"
```

#### to_str

```ruby
uuid.to_str -> String
```

Alias for `to_s`.

#### hex

```ruby
uuid.hex -> String
```

Returns the 32-character hexadecimal representation without hyphens.

**Returns:** A String with 32 lowercase hexadecimal characters.

**Example:**
```ruby
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid.hex  # => "017f22e279b07cc398c4dc0c0c07398f"
```

#### urn

```ruby
uuid.urn -> String
```

Returns the URN representation.

**Returns:** A String in URN format (`urn:uuid:<canonical-form>`).

**Example:**
```ruby
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid.urn  # => "urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
```

### Properties

#### version

```ruby
uuid.version -> Integer
```

Returns the UUID version (0-15).

**Returns:** An Integer representing the version nibble (bits 4-7 of byte 6).

**Example:**
```ruby
Fast::UUID.v7.version    # => 7
Fast::UUID.v4.version    # => 4
Fast::UUID.v1.version    # => 1
Fast::UUID::NIL.version  # => 0
```

#### variant

```ruby
uuid.variant -> Symbol
```

Returns the UUID variant.

**Returns:** One of `:ncs`, `:rfc9562`, `:microsoft`, `:future`.

**Example:**
```ruby
Fast::UUID.v7.variant    # => :rfc9562
Fast::UUID::NIL.variant  # => :ncs
Fast::UUID::MAX.variant  # => :future
```

#### timestamp

```ruby
uuid.timestamp -> Time or nil
```

Returns the timestamp for time-based UUIDs.

**Returns:**
- For v1/v6: A `Time` object representing the Gregorian timestamp (100-ns precision).
- For v7: A `Time` object representing the Unix Epoch timestamp (millisecond precision).
- For other versions: `nil`.

**Note:** The returned `Time` is always in UTC.

**Example:**
```ruby
time = Time.utc(2024, 1, 15, 10, 30, 0)
uuid = Fast::UUID.v7(time: time)
uuid.timestamp  # => 2024-01-15 10:30:00 UTC

Fast::UUID.v4.timestamp  # => nil
```

#### nil_uuid?

```ruby
uuid.nil_uuid? -> true or false
```

Checks if this is the Nil UUID.

**Returns:** `true` if the UUID equals `Fast::UUID::NIL`, `false` otherwise.

**Example:**
```ruby
Fast::UUID::NIL.nil_uuid?  # => true
Fast::UUID.v7.nil_uuid?    # => false
```

#### max_uuid?

```ruby
uuid.max_uuid? -> true or false
```

Checks if this is the Max UUID.

**Returns:** `true` if the UUID equals `Fast::UUID::MAX`, `false` otherwise.

**Example:**
```ruby
Fast::UUID::MAX.max_uuid?  # => true
Fast::UUID.v7.max_uuid?    # => false
```

### Comparison

#### ==

```ruby
uuid == other -> true or false
```

Checks equality with another UUID.

**Parameters:**
- `other` (Object) — The object to compare with.

**Returns:** `true` if `other` is a `Fast::UUID` with the same bytes, `false` otherwise.

**Example:**
```ruby
uuid1 = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid2 = Fast::UUID.new(uuid1.bytes)
uuid1 == uuid2  # => true
uuid1 == "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"  # => false
```

#### eql?

```ruby
uuid.eql?(other) -> true or false
```

Alias for `==`.

#### <=>

```ruby
uuid <=> other -> -1, 0, 1, or nil
```

Compares this UUID with another.

**Parameters:**
- `other` (Object) — The object to compare with.

**Returns:**
- `-1` if `uuid < other`
- `0` if `uuid == other`
- `1` if `uuid > other`
- `nil` if `other` is not a `Fast::UUID`

**Note:** Comparison is based on the raw 16-byte value (opaque unsigned 128-bit). v6 and v7 sort chronologically; v1 does not.

**Example:**
```ruby
uuid1 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 10, 0, 0))
uuid2 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 11, 0, 0))
uuid1 <=> uuid2  # => -1
uuid2 <=> uuid1  # => 1
uuid1 <=> uuid1  # => 0
```

#### hash

```ruby
uuid.hash -> Integer
```

Returns a hash value for use in hash tables.

**Returns:** An Integer hash based on the raw bytes.

**Example:**
```ruby
uuid = Fast::UUID.v7
hash = { uuid => "value" }
hash[uuid]  # => "value"
```

---

## Error Classes

### Fast::UUID::Error

Base error class for all fast-uuid errors. Inherits from `StandardError`.

### Fast::UUID::ParseError

Raised when a string cannot be parsed as a valid RFC 9562 UUID.

**Inherits:** `Fast::UUID::Error`

**Example:**
```ruby
begin
  Fast::UUID.parse("not-a-uuid")
rescue Fast::UUID::ParseError => e
  puts e.message  # => "not a valid UUID: not-a-uuid"
end
```

---

## Summary of All Methods

### Class Methods

| Method | Description |
|--------|-------------|
| `v4` | Generate v4 UUID (random) |
| `uuid_v4` | Generate v4 UUID as string |
| `v7(time: Time.now)` | Generate v7 UUID (Unix Epoch) |
| `uuid_v7(time: Time.now)` | Generate v7 UUID as string |
| `v1(time:, node:, clock_sequence:)` | Generate v1 UUID (Gregorian) |
| `uuid_v1(time:, node:, clock_sequence:)` | Generate v1 UUID as string |
| `v6(time:, node:, clock_sequence:)` | Generate v6 UUID (Gregorian, sortable) |
| `uuid_v6(time:, node:, clock_sequence:)` | Generate v6 UUID as string |
| `v3(namespace, name)` | Generate v3 UUID (MD5-based) |
| `uuid_v3(namespace, name)` | Generate v3 UUID as string |
| `v5(namespace, name)` | Generate v5 UUID (SHA-1-based) |
| `uuid_v5(namespace, name)` | Generate v5 UUID as string |
| `generate` | Generate UUID (v7, RFC default) |
| `uuid` | Generate UUID as string (v7) |
| `parse(str)` | Parse UUID string |
| `parse?(str)` | Parse UUID string, return nil on failure |
| `valid?(str)` | Check if string is valid UUID |
| `new(bytes)` | Create UUID from 16-byte string |

### Instance Methods

| Method | Description |
|--------|-------------|
| `bytes` | Raw 16-byte binary string |
| `to_s` | Canonical string representation |
| `to_str` | Alias for `to_s` |
| `hex` | 32-char hex string without hyphens |
| `urn` | URN format string |
| `version` | UUID version (0-15) |
| `variant` | UUID variant symbol |
| `timestamp` | Timestamp for time-based UUIDs |
| `nil_uuid?` | Check if Nil UUID |
| `max_uuid?` | Check if Max UUID |
| `==(other)` | Equality check |
| `eql?(other)` | Equality check (alias) |
| `<=> (other)` | Comparison |
| `hash` | Hash value |

### Constants

| Constant | Description |
|----------|-------------|
| `VERSION` | Gem version string |
| `NIL` | Nil UUID (all zeros) |
| `MAX` | Max UUID (all ones) |
| `NAMESPACE_DNS` | DNS namespace UUID |
| `NAMESPACE_URL` | URL namespace UUID |
| `NAMESPACE_OID` | OID namespace UUID |
| `NAMESPACE_X500` | X.500 namespace UUID |
