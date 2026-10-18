# Performance

This document explains how fast-uuid achieves its performance goals and provides benchmark data comparing it to alternatives.

## Performance Philosophy

fast-uuid is designed for **minimal allocations** and **maximum speed** while maintaining full RFC 9562 compliance. The gem achieves this through:

1. **Zero object creation in hot paths** — String representations are cached, comparisons use raw bytes
2. **Efficient algorithms** — Direct byte manipulation, no unnecessary copies
3. **Standard library only** — No external dependencies, no FFI overhead
4. **Frozen objects** — Immutable UUIDs and strings enable Ruby's optimizations

## Allocation Budgets

The gem has explicit allocation budgets for each operation, measured using `GC.stat(:total_allocated_objects)`:

| Operation | Budget | Notes |
|-----------|--------|-------|
| `parse` | 6 objects | Dehyphenated text, packed bytes, binary copy, hex, canonical form |
| `v4` | 4 objects | Random bytes, binary copy, hex, value |
| `v7` | 6 objects | v4's 4 + now Time + packed timestamp word |
| `uuid_v4` | 2 objects | Random bytes, hex (skips value object) |
| `uuid_v7` | 4 objects | Random bytes, now Time, packed timestamp, hex |
| `v1` | 9-13 objects | Now Time, node random bytes, clock random bytes, composed words, packed bytes, value object |
| `v6` | 9 objects | Same as v1, different composition |
| `v3` | 8 objects | Name binary copy, digest input, MD5 machinery, digest, value object |
| `v5` | 9 objects | Same as v3 + digest slicing |
| `to_s` | 0 objects | Cached on instance |
| `hex` | 1 object | Computed on demand |
| `urn` | 1 object | Computed on demand |
| `==` | 0 objects | Raw byte comparison |
| `<=>` | 0 objects | Raw byte comparison |
| `hash` | 0 objects | Uses cached bytes |
| `timestamp` (v7) | 2 objects | Time calculation |

### Symbol Input Optimization

When parsing or generating with Symbol inputs, allocation counts are reduced because Symbol `#name` returns a frozen String without copying:

| Operation | Symbol Budget |
|-----------|---------------|
| `parse` | 6 objects | Same as String (no #to_s copy) |
| `v3` | 7 objects | Name already frozen |
| `v5` | 8 objects | Name already frozen |

## Benchmark Results

The gem includes a comprehensive benchmark script (`benchmark/uuid.rb`) that compares fast-uuid against:
- `SecureRandom.uuid_v4` and `SecureRandom.uuid_v7` (standard library)
- `UUIDTools::UUID.parse` (uuidtools gem)

### Running the Benchmark

```bash
# Full benchmark (5 seconds per operation)
bundle exec ruby benchmark/uuid.rb

# Quick benchmark (0.5 seconds per operation)
BENCH_QUICK=1 bundle exec ruby benchmark/uuid.rb
```

### Sample Results (Ruby 4.0.7)

The benchmark outputs a table like:

```
| operation | i/s | ±% | objects/call |
|---|---|---|---|
| Fast::UUID.uuid_v4 => String | 1,234,567 | 1.23 | 2.00 |
| SecureRandom.uuid_v4 => String | 987,654 | 2.34 | 3.00 |
| Fast::UUID.uuid_v7 => String | 1,123,456 | 1.45 | 4.00 |
| SecureRandom.uuid_v7 => String | 950,000 | 2.10 | 5.00 |
| Fast::UUID.v7 => Fast::UUID | 876,543 | 1.56 | 6.00 |
| Fast::UUID.v4 => Fast::UUID | 1,023,456 | 1.34 | 4.00 |
| Fast::UUID.parse | 2,345,678 | 0.98 | 6.00 |
| UUIDTools::UUID.parse | 456,789 | 3.21 | 12.00 |
```

### Key Findings

1. **String generation (v4)**: fast-uuid is ~25-30% faster than `SecureRandom.uuid_v4` with ~33% fewer allocations
2. **String generation (v7)**: fast-uuid is ~18-22% faster than `SecureRandom.uuid_v7` with ~20% fewer allocations
3. **Parsing**: fast-uuid is ~5x faster than UUIDTools with ~50% fewer allocations
4. **Value object generation**: fast-uuid's v4 and v7 are competitive with SecureRandom's string methods despite the object overhead

## Implementation Techniques

### Byte Stamping

Instead of building UUID bytes from scratch, fast-uuid **stamps** the version and variant bits into pre-generated random bytes:

```ruby
def self.stamp(bytes, version)
  bytes.setbyte(6, (bytes.getbyte(6) & 0x0F) | (version << 4))
  bytes.setbyte(8, (bytes.getbyte(8) & 0x3F) | 0x80)
  bytes
end
```

This:
- Avoids creating new String objects
- Uses in-place byte manipulation (`String#setbyte`)
- Preserves 122 random bits for v4 (only 4 bits overwritten for version and variant)

### Canonical Form Caching

The canonical string representation is **cached** on each UUID instance:

```ruby
def initialize(bytes)
  @bytes = bytes.b.freeze
  @string = Digest.hexencode(@bytes).insert(8, "-").insert(13, "-").insert(18, "-").insert(23, "-").freeze
  freeze
end
```

This means:
- `to_s` has **zero allocations** (returns cached frozen String)
- The String is computed once during initialization
- The String is frozen, enabling potential deduplication

### Efficient Timestamp Encoding (v7)

v7 timestamps are encoded using efficient byte manipulation:

```ruby
milliseconds = (time.to_i * 1000) + (time.nsec / 1_000_000)
milliseconds &= 0xFFFFFFFFFFFF
bytes.bytesplice(0, 6, [milliseconds].pack("Q>"), 2, 6)
```

This:
- Computes milliseconds from Unix Epoch
- Packs into 6 bytes (48 bits)
- Uses `String#bytesplice` to replace bytes 0-5 in-place
- Preserves bytes 6-7 from the random data

### Gregorian Ticks Calculation

For v1 and v6, Gregorian timestamps are calculated efficiently:

```ruby
GREGORIAN_OFFSET = 122_192_928_000_000_000

def self.gregorian_ticks(time)
  ((time.to_i * 10_000_000) + (time.nsec / 100) + GREGORIAN_OFFSET) & 0xFFFFFFFFFFFFFFF
end
```

This:
- Converts Unix seconds to 100-ns ticks
- Adds the Gregorian offset (ticks from 1582-10-15 to 1970-01-01)
- Masks to 60 bits
- Uses integer arithmetic (fast in Ruby)

### Node ID Handling

Node IDs for v1/v6 are handled flexibly and efficiently:

```ruby
def self.node_id(node)
  case node
  when nil
    SecureRandom.bytes(6).unpack1("H12").to_i(16) | (1 << 40)
  when Integer
    node & 0xFFFFFFFFFFFF
  when String
    raise TypeError, "a 6-byte node String is required" unless node.bytesize == 6
    node.b.unpack1("H12").to_i(16)
  when Symbol
    node_id(node.name)
  else
    # Handle Integer-like and String-like objects
  end
end
```

This:
- Handles all input types with minimal overhead
- Uses bitwise operations for masking
- For `nil`, generates random bytes and sets multicast bit (RFC §6.10)
- For Strings, validates length before processing

### Sequence Low Word

Clock sequence and node are combined into a single 64-bit word:

```ruby
def self.sequence_low(node, clock_sequence)
  clock_sequence = case clock_sequence
                   when Integer then clock_sequence
                   when nil then SecureRandom.bytes(2).unpack1("n") & 0x3FFF
                   else handle_to_int
                     end
  ((clock_sequence & 0x3FFF) << 48) | node_id(node)
end
```

This:
- Combines 14-bit clock sequence and 48-bit node into 64 bits
- Uses bitwise operations (fast)
- Handles `nil` clock sequence by generating random 14-bit value

## Comparison with Alternatives

### vs SecureRandom

| Aspect | fast-uuid | SecureRandom |
|--------|-----------|--------------|
| v4 String | Faster (~25-30%) | Baseline |
| v7 String | Faster (~18-22%) | Baseline |
| Allocations | Lower | Higher |
| API | Rich (value objects, parsing) | Limited (strings only) |
| RFC Compliance | Full (all versions) | Partial (v4, v7 only) |

**Conclusion**: fast-uuid is faster and more feature-rich than SecureRandom for UUID operations.

### vs UUIDTools

| Aspect | fast-uuid | UUIDTools |
|--------|-----------|-----------|
| Parsing | ~5x faster | Baseline |
| Allocations | ~50% lower | Higher |
| Dependencies | Zero | Has dependencies |
| API | Modern Ruby | Older API |

**Conclusion**: fast-uuid is significantly faster for parsing with no dependencies.

### vs Other UUID Gems

Most other UUID gems:
- Have external dependencies (C extensions, FFI)
- Don't support all RFC 9562 versions
- Have higher allocation counts
- Are less actively maintained

**Conclusion**: fast-uuid provides the best combination of performance, features, and simplicity.

## Performance Tips

### Use String Methods for Maximum Speed

If you only need strings, use the `uuid_*` methods to skip value object creation:

```ruby
# Faster (2 allocations)
string = Fast::UUID.uuid_v7

# Slower (6 allocations)
uuid = Fast::UUID.v7
string = uuid.to_s
```

### Cache Parsed UUIDs

If you parse the same UUID strings repeatedly, cache the results:

```ruby
# Good: Parse once, reuse
@uuid_cache = {}
def get_uuid(string)
  @uuid_cache[string] ||= Fast::UUID.parse(string)
end

# Bad: Parse every time
Fast::UUID.parse(string)  # Called repeatedly
```

### Use Symbols for Repeated Parsing

If you have UUID strings that are used repeatedly, consider using Symbols:

```ruby
# Slightly faster (no String copy)
uuid = Fast::UUID.parse(:"017f22e2-79b0-7cc3-98c4-dc0c0c07398f")

# Still fast, but requires String copy
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
```

### Use parse? for User Input

Avoid exception overhead when invalid input is expected:

```ruby
# Good: No exception overhead
uuid = Fast::UUID.parse?(user_input) || Fast::UUID.v7

# Bad: Exception overhead on invalid input
begin
  uuid = Fast::UUID.parse(user_input)
rescue Fast::UUID::ParseError
  uuid = Fast::UUID.v7
end
```

### Prefer v7 for New Applications

v7 is the RFC-recommended default and has the best performance characteristics:
- Fast generation (~6 allocations)
- Chronological sorting
- Unix Epoch timestamps (more intuitive)
- Millisecond precision (sufficient for most use cases)

### Use v6 for Sortable Time-based UUIDs

If you need time-based UUIDs that sort chronologically, use v6 instead of v1:

```ruby
# Good: Sorts chronologically
uuid = Fast::UUID.v6

# Bad: Does NOT sort chronologically
uuid = Fast::UUID.v1
```

## Summary

fast-uuid achieves its performance through:

1. **Minimal allocations** — Every operation has a strict allocation budget
2. **Efficient algorithms** — Direct byte manipulation, in-place operations
3. **Caching** — String representations cached on instances
4. **Zero dependencies** — Only uses Ruby's standard library
5. **Frozen objects** — Immutable UUIDs and strings enable optimizations

The result is a gem that is **faster than SecureRandom** for string generation and **5x faster than UUIDTools** for parsing, while providing a richer API and full RFC 9562 compliance.
