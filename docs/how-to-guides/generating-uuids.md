# Generating UUIDs

This guide covers all UUID generation options available in fast-uuid.

## Random UUIDs (v4)

Version 4 UUIDs use 122 random bits from the cryptographically secure pseudorandom number generator (CSPRNG).

### As a value object

```ruby
uuid = Fast::UUID.v4
uuid.version  # => 4
uuid.variant  # => :rfc9562
uuid.to_s     # => "919108f7-52d1-4320-9bac-f847db4148a8"
```

### As a string

```ruby
string = Fast::UUID.uuid_v4
# => "919108f7-52d1-4320-9bac-f847db4148a8"
```

This is a drop-in replacement for `SecureRandom.uuid_v4`.

## Time-based UUIDs (v7 - Recommended)

Version 7 uses a Unix Epoch timestamp in milliseconds (48 bits) combined with 74 random bits. It sorts chronologically as raw bytes.

### As a value object

```ruby
# Default: uses current time
uuid = Fast::UUID.v7

# With explicit time (millisecond precision)
time = Time.utc(2024, 1, 15, 10, 30, 0)
uuid = Fast::UUID.v7(time: time)

uuid.version     # => 7
uuid.variant     # => :rfc9562
uuid.timestamp   # => 2024-01-15 10:30:00 UTC
uuid.to_s        # => "018e312f-4b1e-7000-8000-000000000000"
```

### As a string

```ruby
string = Fast::UUID.uuid_v7
# => "018e312f-4b1e-7000-8000-000000000000"
```

This is a drop-in replacement for `SecureRandom.uuid_v7`.

### Sub-millisecond precision

v7 timestamps are stored in milliseconds. Sub-millisecond values are truncated:

```ruby
time = Time.utc(2024, 1, 15, 10, 30, 0, 123_456)  # 123456 microseconds
uuid = Fast::UUID.v7(time: time)
uuid.timestamp  # => 2024-01-15 10:30:00.123 UTC (truncated to milliseconds)
```

## Time-based UUIDs (v1 - Legacy)

Version 1 uses a 60-bit Gregorian timestamp (100-nanosecond ticks since 1582-10-15) with a clock sequence and node identifier.

### Basic generation

```ruby
uuid = Fast::UUID.v1
uuid.version  # => 1
uuid.variant  # => :rfc9562
```

### With explicit parameters

```ruby
time = Time.utc(2024, 1, 15, 10, 30, 0)
node = 0x9F6BDECED846  # 48-bit node identifier
clock_sequence = 0x33C8  # 14-bit clock sequence

uuid = Fast::UUID.v1(
  time: time,
  node: node,
  clock_sequence: clock_sequence
)
```

### Node specification

The `node` parameter accepts multiple formats:

```ruby
# Integer (masked to 48 bits)
Fast::UUID.v1(node: 0xFFFFFFFFFFFF)  # => node = 0xbfffffffffff

# String (exactly 6 bytes)
Fast::UUID.v1(node: "\x9f\x6b\xde\xce\xd8\x46")

# Symbol (uses symbol name as string)
Fast::UUID.v1(node: :my_node)  # equivalent to node: "my_node"

# Integer-like (responds to #to_int)
node_obj = Object.new
def node_obj.to_int
  0x9F6BDECED846
end
Fast::UUID.v1(node: node_obj)

# nil (generates random node with multicast bit set)
Fast::UUID.v1(node: nil)
```

### Clock sequence specification

```ruby
# Integer (masked to 14 bits)
Fast::UUID.v1(clock_sequence: 0x3FFF)  # maximum 14-bit value

# Integer-like (responds to #to_int)
clock_obj = Object.new
def clock_obj.to_int
  0x33C8
end
Fast::UUID.v1(clock_sequence: clock_obj)

# nil (generates random 14-bit value)
Fast::UUID.v1(clock_sequence: nil)
```

### As a string

```ruby
string = Fast::UUID.uuid_v1(time: time, node: node, clock_sequence: clock_sequence)
# => "c232ab00-9414-11ec-b3c8-9f6bdeced846"
```

### Important note about v1 sorting

v1 UUIDs do **not** sort chronologically as raw bytes because the timestamp fields are stored least-significant-first. Use v6 or v7 for chronological sorting.

## Time-based UUIDs (v6 - Reordered)

Version 6 is the "reordered" version of v1. It uses the same 60-bit Gregorian timestamp but stores fields most-significant-first, enabling chronological sorting.

### Basic generation

```ruby
uuid = Fast::UUID.v6
uuid.version  # => 6
uuid.variant  # => :rfc9562
```

### With explicit parameters

Same parameters as v1:

```ruby
time = Time.utc(2024, 1, 15, 10, 30, 0)
node = 0x9F6BDECED846
clock_sequence = 0x33C8

uuid = Fast::UUID.v6(
  time: time,
  node: node,
  clock_sequence: clock_sequence
)
```

### As a string

```ruby
string = Fast::UUID.uuid_v6(time: time, node: node, clock_sequence: clock_sequence)
# => "1ec9414c-232a-6b00-b3c8-9f6bdeced846"
```

### Chronological sorting

```ruby
t1 = Time.utc(2024, 1, 15, 10, 0, 0)
t2 = Time.utc(2024, 1, 15, 11, 0, 0)
t3 = Time.utc(2024, 1, 15, 10, 30, 0)

uuids = [
  Fast::UUID.v6(time: t2),
  Fast::UUID.v6(time: t1),
  Fast::UUID.v6(time: t3)
]

sorted = uuids.sort
# => [v6(t1), v6(t3), v6(t2)] - chronological order
```

## Name-based UUIDs (v3)

Version 3 uses MD5 to generate a UUID from a namespace and a name.

### Basic generation

```ruby
namespace = Fast::UUID::NAMESPACE_DNS
name = "www.example.com"

uuid = Fast::UUID.v3(namespace, name)
uuid.version  # => 3
uuid.variant  # => :rfc9562
uuid.to_s     # => "5df41881-3aed-3515-88a7-2f4a814cf09e"
```

### As a string

```ruby
string = Fast::UUID.uuid_v3(namespace, name)
# => "5df41881-3aed-3515-88a7-2f4a814cf09e"
```

### Namespace options

Built-in namespaces (from RFC 9562 Appendix A):

```ruby
Fast::UUID::NAMESPACE_DNS   # 6ba7b810-9dad-11d1-80b4-00c04fd430c8
Fast::UUID::NAMESPACE_URL   # 6ba7b811-9dad-11d1-80b4-00c04fd430c8
Fast::UUID::NAMESPACE_OID   # 6ba7b812-9dad-11d1-80b4-00c04fd430c8
Fast::UUID::NAMESPACE_X500  # 6ba7b814-9dad-11d1-80b4-00c04fd430c8
```

### Custom namespaces

You can use any UUID as a namespace:

```ruby
custom_namespace = Fast::UUID.parse("12345678-1234-5678-1234-567812345678")
uuid = Fast::UUID.v3(custom_namespace, "my-name")
```

### Name formats

Names can be any string-like object:

```ruby
# String
Fast::UUID.v3(namespace, "example.com")

# Symbol (uses #name)
Fast::UUID.v3(namespace, :example_com)

# Object with #to_s
name_obj = Object.new
def name_obj.to_s
  "example.com"
end
Fast::UUID.v3(namespace, name_obj)
```

### Deterministic output

The same namespace and name always produce the same UUID:

```ruby
uuid1 = Fast::UUID.v3(namespace, "example.com")
uuid2 = Fast::UUID.v3(namespace, "example.com")
uuid1 == uuid2  # => true
```

## Name-based UUIDs (v5)

Version 5 is identical to v3 but uses SHA-1 instead of MD5.

### Basic generation

```ruby
namespace = Fast::UUID::NAMESPACE_DNS
name = "www.example.com"

uuid = Fast::UUID.v5(namespace, name)
uuid.version  # => 5
uuid.variant  # => :rfc9562
uuid.to_s     # => "2ed6657d-e927-568b-95e1-2665a8aea6a2"
```

### As a string

```ruby
string = Fast::UUID.uuid_v5(namespace, name)
# => "2ed6657d-e927-568b-95e1-2665a8aea6a2"
```

All other behaviors (namespaces, name formats, determinism) are identical to v3.

## Default generation

For convenience, fast-uuid provides default generators:

```ruby
# Generate a v7 UUID (RFC-recommended default)
uuid = Fast::UUID.generate
uuid.version  # => 7

# Generate a v7 UUID as a string
string = Fast::UUID.uuid
# => "018e312f-4b1e-7000-8000-000000000000"
```

## RFC 9562 Test Vectors

The gem correctly generates all test vectors from RFC 9562 Appendix A:

```ruby
# v1 test vector
uuid = Fast::UUID.v1(
  time: Time.utc(2022, 2, 22, 19, 22, 22),
  clock_sequence: 0x33C8,
  node: 0x9F6BDECED846
)
uuid.to_s  # => "c232ab00-9414-11ec-b3c8-9f6bdeced846"

# v6 test vector (same fields, reordered)
uuid = Fast::UUID.v6(
  time: Time.utc(2022, 2, 22, 19, 22, 22),
  clock_sequence: 0x33C8,
  node: 0x9F6BDECED846
)
uuid.to_s  # => "1ec9414c-232a-6b00-b3c8-9f6bdeced846"

# v3 test vector
uuid = Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com")
uuid.to_s  # => "5df41881-3aed-3515-88a7-2f4a814cf09e"

# v5 test vector
uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
uuid.to_s  # => "2ed6657d-e927-568b-95e1-2665a8aea6a2"

# v4 test vector (example)
uuid = Fast::UUID.parse("919108f7-52d1-4320-9bac-f847db4148a8")
uuid.version  # => 4

# v7 test vector
uuid = Fast::UUID.v7(time: Time.utc(2022, 2, 22, 19, 22, 22))
uuid.to_s  # => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
```

## Thread safety

All generation methods are thread-safe. Each call generates independent random values:

```ruby
threads = 8.times.map do
  Thread.new { 1000.times.map { Fast::UUID.v7 } }
end

uuids = threads.flat_map(&:value)
uuids.uniq.length == uuids.length  # => true (all unique)
```
