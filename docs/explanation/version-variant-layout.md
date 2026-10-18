# How the versions and variants are laid out

## The version nibble

The version occupies the high nibble of byte 6. It is stamped with `setbyte` and read by `#version`:

```ruby
# stamp
bytes.setbyte(6, (bytes.getbyte(6) & 0x0F) | (version << 4))

# read
@bytes.getbyte(6) >> 4  # => 0-15
```

All 16 version values (0–15) are valid per the grammar-only rule. The RFC assigns 1, 3, 4, 5, 6, and 7; others report their nibble without interpretation.

## The variant bits

The variant occupies the top two bits of byte 8:

```ruby
case @bytes.getbyte(8) >> 5
when 0b100, 0b101 then :rfc9562   # 10xx
when 0b110        then :microsoft # 110x
when 0b111        then :future    # 111x
else                  :ncs        # 0xxx
end
```

- `10xx` → `:rfc9562` — the RFC 9562 variant, used by all fast-uuid generators.
- `110x` → `:microsoft` — the Microsoft GUID variant.
- `111x` → `:future` — reserved for future definition; `MAX` lands here.
- `0xxx` → `:ncs` — the NCS variant; `NIL` lands here.

## v4

128 CSPRNG bits from `SecureRandom.bytes(16)`, 122 stay random. One nibble is the version (4) and the top two bits are the `10xx` variant:

```ruby
stamp(SecureRandom.bytes(16), 4)
```

`#timestamp` answers `nil` for v4.

## v7

48-bit `unix_ts_ms` truncated to whole milliseconds, then 12 random `rand_a` bits and 62 random `rand_b` bits for 74 random bits total:

```ruby
milliseconds = (time.to_i * 1000) + (time.nsec / 1_000_000)
milliseconds &= 0xFFFFFFFFFFFF
bytes.bytesplice(0, 6, [milliseconds].pack("Q>"), 2, 6)
stamp(bytes, 7)
```

The masked `unix_ts_ms` rides in the middle six bytes of an 8-byte big-endian word, leaving bytes 6–7 to the `rand_a` they already hold. Sub-millisecond precision is truncated.

`#timestamp` reconstructs a UTC `Time` at millisecond resolution:

```ruby
milliseconds = @bytes[0, 8].unpack1("Q>") >> 16
Time.at(milliseconds / 1000, (milliseconds % 1000) * 1_000_000, :nanosecond).utc
```

v7 sorts chronologically as raw bytes because the timestamp is the most-significant field.

## v1 and v6

Both use a 60-bit 100-ns Gregorian timestamp with a fixed offset between the Gregorian epoch (1582-10-15) and the Unix epoch:

```ruby
GREGORIAN_OFFSET = 122_192_928_000_000_000  # 100-ns ticks
```

```ruby
def self.gregorian_ticks(time)
  ((time.to_i * 10_000_000) + (time.nsec / 100) + GREGORIAN_OFFSET) & 0xFFFFFFFFFFFFFFF
end
```

Both carry a 14-bit `clock_seq` over a 48-bit node with the `10xx` variant stamped after the pack:

```ruby
def self.sequence_low(node, clock_sequence)
  ((clock_sequence & 0x3FFF) << 48) | node_id(node)
end
```

The difference is field order on the wire:

- **v1** lays `time_low` first (least-significant 32 bits of the timestamp, then `time_mid`, then `time_hi` under version nibble 1):

  ```ruby
  bytes = [((ticks & 0xFFFFFFFF) << 32) | (((ticks >> 32) & 0xFFFF) << 16) | (ticks >> 48),
           sequence_low(node, clock_sequence)].pack("Q> Q>")
  stamp(bytes, 1)
  ```

  Read back:

  ```ruby
  gregorian(((@bytes[6, 2].unpack1("n") & 0x0FFF) << 48) | (@bytes[4, 2].unpack1("n") << 32) |
            @bytes[0, 4].unpack1("N"))
  ```

  v1 does **not** sort chronologically because `time_low` sits first — the least-significant field is most-significant on the wire.

- **v6** reorders most-significant-first (RFC 9562 Section 5.6, the v1 migration version): `time_high`, then `time_mid`, then `time_low` under version nibble 6:

  ```ruby
  bytes = [((ticks >> 28) << 32) | (((ticks >> 12) & 0xFFFF) << 16) | (ticks & 0xFFF),
           sequence_low(node, clock_sequence)].pack("Q> Q>")
  stamp(bytes, 6)
  ```

  Read back:

  ```ruby
  gregorian((@bytes[0, 4].unpack1("N") << 28) | (@bytes[4, 2].unpack1("n") << 12) |
            (@bytes[6, 2].unpack1("n") & 0x0FFF))
  ```

  v6 does sort chronologically — same timestamp, same node and clock sequence as v1, only the wire order changes.

Both reconstruct a UTC `Time` at 100-ns resolution. v7 truncates to milliseconds; v1 and v6 preserve the finer grid.

## v3 and v5

Both digest over `namespace.bytes + name.b`:

```ruby
def self.digest_input(namespace, name)
  name = implicit_string(name)
  namespace = namespace.is_a?(UUID) ? namespace : parse(namespace)
  namespace.bytes + name.b
end
```

- v3: MD5, whole 128-bit digest:

  ```ruby
  stamp(Digest::MD5.digest(digest_input(namespace, name)), 3)
  ```

- v5: SHA-1, leftmost 128 bits of the 160-bit digest (rightmost 32 discarded):

  ```ruby
  stamp(Digest::SHA1.digest(digest_input(namespace, name)).byteslice(0, 16), 5)
  ```

The namespace may be a UUID value object or any String-like value that parses; the name is its String form (`to_s` / Symbol `name`).

## Nil and Max

- `NIL` is all-zero bytes:

  ```ruby
  Fast::UUID::NIL = Fast::UUID.new(("\0" * 16).b)
  ```

- `MAX` is all-`FF` bytes:

  ```ruby
  Fast::UUID::MAX = Fast::UUID.new(("\xFF" * 16).b)
  ```

Both are valid per the grammar-only rule. NIL reports version 0 / `:ncs`; MAX reports version 15 / `:future`:

```ruby
Fast::UUID::NIL.version # => 0
Fast::UUID::NIL.variant # => :ncs
Fast::UUID::MAX.version # => 15
Fast::UUID::MAX.variant # => :future
```

They bracket every UUID in opaque unsigned 128-bit byte order.
