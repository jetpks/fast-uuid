# Order, compare and key UUIDs

## Sorting

`Fast::UUID` includes `Comparable`. `#<=>` is opaque unsigned 128-bit byte order and answers `nil` against non-UUIDs.

```ruby
require "fast/uuid"

a = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
b = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398e")
a <=> b # => 1
b <=> a # => -1
a <=> a # => 0
a <=> "not-a-uuid" # => nil
a <=> a.to_s       # => nil

[a, b].sort # => [b, a]
```

v7 and v6 sort chronologically as raw bytes:

```ruby
time = Time.utc(2022, 2, 22, 19, 22, 22)
v7s = [
  Fast::UUID.v7(time: time + 2),
  Fast::UUID.v7(time: time),
  Fast::UUID.v7(time: time + 1)
]
v7s.sort.map(&:timestamp) # => [time, time + 1, time + 2]
```

v1 does not — its `time_low` field sits first on the wire. See [How the versions and variants are laid out](../explanation/version-variant-layout.md).

## Equality and hashing

`#==` is true only for another `Fast::UUID` with identical 16 bytes. `eql?` aliases `==`. `#hash` is over `bytes` — UUIDs are safe as `Hash` and `Set` keys.

```ruby
parsed = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
from_bytes = Fast::UUID.new(parsed.bytes)

parsed == from_bytes   # => true
parsed.eql?(from_bytes) # => true
parsed.hash == from_bytes.hash # => true

other = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398e")
parsed == other # => false
parsed.hash == other.hash # => false
```

Provenance is irrelevant — parse and `new(bytes)` are equal. A UUID never equals its String:

```ruby
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid == uuid.to_s # => false
uuid.eql?(uuid.to_s) # => false
```

Useful as hash keys:

```ruby
h = {}
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
h[uuid] = 1
h[Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")] # => 1
h[Fast::UUID.new(uuid.bytes)] # => 1
```

## Sentinels

`Fast::UUID::NIL` (all-zero bytes) and `Fast::UUID::MAX` (all-`FF` bytes) are frozen constants. `nil_uuid?` and `max_uuid?` test for them:

```ruby
Fast::UUID::NIL.to_s # => "00000000-0000-0000-0000-000000000000"
Fast::UUID::MAX.to_s # => "ffffffff-ffff-ffff-ffff-ffffffffffff"

Fast::UUID::NIL.nil_uuid? # => true
Fast::UUID::NIL.max_uuid? # => false
Fast::UUID::MAX.max_uuid? # => true
Fast::UUID::MAX.nil_uuid? # => false

Fast::UUID.parse("00000000-0000-0000-0000-000000000000").nil_uuid? # => true
```

They bracket every UUID in order. NIL is version 0 and `:ncs`; MAX is version 15 and `:future`:

```ruby
uuid = Fast::UUID.v4
Fast::UUID::NIL < uuid            # => true
uuid < Fast::UUID::MAX            # => true
Fast::UUID::NIL < Fast::UUID::MAX # => true

Fast::UUID::NIL.version # => 0
Fast::UUID::NIL.variant # => :ncs
Fast::UUID::MAX.version # => 15
Fast::UUID::MAX.variant # => :future
```

## Rebuild from bytes

`Fast::UUID.new(bytes)` builds from the frozen 16-byte binary String returned by `#bytes` and round-trips equality:

```ruby
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid.bytes.bytesize # => 16
uuid.bytes.frozen?  # => true

copy = Fast::UUID.new(uuid.bytes)
copy == uuid        # => true
copy.to_s == uuid.to_s # => true
copy.bytes == uuid.bytes # => true
```

Any 16-byte String of any encoding tag is normalized to binary:

```ruby
utf8 = [uuid.hex].pack("H*").force_encoding(Encoding::UTF_8)
Fast::UUID.new(utf8).bytes.encoding # => Encoding::BINARY
Fast::UUID.new(utf8) == uuid # => true
```

Wrong sizes and non-String-like inputs raise `ArgumentError`:

```ruby
Fast::UUID.new("short") # raises ArgumentError: a 16-byte binary String is required (got 5 bytes)
Fast::UUID.new("017f22e2-79b0-7cc3-98c4-dc0c0c07398f") # raises ArgumentError (36 bytes, not 16)
```
