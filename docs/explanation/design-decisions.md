# Design decisions in fast-uuid

## A frozen value object

`#initialize` freezes the instance and its bytes, and precomputes and freezes `to_s` at construction:

```ruby
@bytes = bytes.b.freeze
@string = Digest.hexencode(@bytes).insert(8, "-").insert(13, "-").insert(18, "-").insert(23, "-").freeze
freeze
```

`Fast::UUID::NIL` and `Fast::UUID::MAX` are frozen constants. Every instance returned by the generators is frozen:

```ruby
uuid = Fast::UUID.v4
uuid.frozen?        # => true
uuid.bytes.frozen?  # => true
uuid.to_s.frozen?   # => true
Fast::UUID::NIL.frozen? # => true
Fast::UUID::MAX.frozen? # => true
```

Consequence: UUIDs are safe to share across threads without copying. Generation is thread-safe because it holds no shared state — see below.

## No dependencies

The runtime uses stdlib `digest` and `securerandom` only. The gemspec declares no runtime dependencies. `uuidtools` and `benchmark-ips` are dev-only comparison references, never runtime:

```ruby
# lib/fast/uuid/uuid.rb
require "digest"
require "securerandom"
```

Dev gems live in `gems.rb`: `sus`, `covered`, `rubocop` in the test group; `benchmark-ips` in the benchmark group; `uuidtools` in the test group as the reference parser for benchmarks.

## Validity is the grammar, nothing more

The RFC defines no version or variant gate. fast-uuid validates only the canonical grammar:

- `4hexOctet-2hexOctet-2hexOctet-2hexOctet-6hexOctet`, case-insensitive.
- Any version (0–15) and any variant parses. v0, v15, NCS, Microsoft, and Future variants are all valid:

```ruby
Fast::UUID.valid?("ffffffff-ffff-0fff-0fff-ffffffffffff") # => true  # v0, NCS
Fast::UUID.valid?("ffffffff-ffff-ffff-cfff-ffffffffffff") # => true  # v15, Microsoft
Fast::UUID.valid?("ffffffff-ffff-ffff-ffff-ffffffffffff") # => true  # v15, Future (Max)
```

Nil and Max sit outside the `10xx` variant by design and are not excluded:

```ruby
Fast::UUID::NIL.version # => 0
Fast::UUID::NIL.variant # => :ncs
Fast::UUID::MAX.version # => 15
Fast::UUID::MAX.variant # => :future
Fast::UUID.valid?("00000000-0000-0000-0000-000000000000") # => true
Fast::UUID.valid?("ffffffff-ffff-ffff-ffff-ffffffffffff") # => true
```

## Comparison is opaque byte order

`#<=>` compares raw bytes, never a field:

```ruby
bytes <=> other.bytes if other.is_a?(UUID)
```

`#==` is 128-bit identity over the same bytes:

```ruby
other.is_a?(UUID) && other.bytes == bytes
```

`eql?` aliases `==` and `hash` is over `bytes`, so UUIDs work as `Hash`/`Set` keys. The version nibble is not privileged — sorting is a property of the layout, not the comparator.

v6 and v7 sort chronologically because their most-significant bits are the timestamp. v1 does not because its `time_low` field sits first. See [How the versions and variants are laid out](version-variant-layout.md).

## Allocation discipline

`to_s`, `==`, `eql?`, `<=>`, and `hash` allocate 0 objects. `hex` and `urn` allocate 1. The budgets are pinned in `test/fast/uuid/allocations.rb` and are exact on Ruby 4.0.7.

Detailed numbers live in [Performance and allocations](performance.md) — allocation budgets are not repeated here.

## v7 has no counter and no shared state

Every UUID is a fresh CSPRNG draw:

```ruby
# v7: unix_ts_ms truncated to whole ms + rand_a/rand_b from SecureRandom
# v4: 128 CSPRNG bits from SecureRandom.bytes(16)
```

No counter and no shared state means generation is thread-safe and collision-safe without coordination:

```ruby
uuids = Array.new(8) do
  Thread.new { Array.new(250) { [Fast::UUID.v7, Fast::UUID.v1, Fast::UUID.v6].sample } }
end.flat_map(&:value)
uuids.map(&:to_s).uniq.length # => 2000
```

The random tails are independent even within one millisecond:

```ruby
time = Time.utc(2022, 2, 22, 19, 22, 22)
many = Array.new(10_000) { Fast::UUID.v7(time: time) }
many.map(&:to_s).uniq.length # => 10000
many.map(&:timestamp).uniq.length # => 1
```
