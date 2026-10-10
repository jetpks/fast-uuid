# How to store a UUID as 16 bytes

Keep a UUID in a BLOB or `bytea` column, a binary cache key or a wire payload, and read
it back out. You need `#bytes` and `Fast::UUID.new`.

## Steps

1. Write the raw 16 bytes. `#bytes` returns the value as a frozen binary String:

   ```ruby
   uuid = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
   uuid.bytes       # => 16-byte binary String
   uuid.bytesize    # => 16, against 36 for to_s and 32 for hex
   ```

   `#hex` is the middle form, the same 128 bits as 32 lowercase hex characters, when
   the column is text and the bytes would need quoting anyway.

2. Read it back with `Fast::UUID.new`, which takes a 16-byte binary String:

   ```ruby
   Fast::UUID.new(uuid.bytes) == uuid # => true
   ```

   Anything else raises `ArgumentError`: a non-String, and a String of any other
   length. An encoding tag on a 16-byte String is normalized to binary rather than
   rejected, so a UTF-8 column that happens to hold pure ASCII bytes still round-trips.

3. For a value you already hold as text, parse first and store after — one
   canonicalization on the way in:

   ```ruby
   stored = Fast::UUID.parse(row["request_id"]).bytes
   ```

## Notes

The RFC recommends storing UUIDs as 128-bit binary where the storage allows it
(RFC 9562 §6.13), and 16 bytes is also what `#<=>` compares, so an index on the byte
column sorts exactly as `sort` does;
[In what order UUIDs sort](../explanation/comparison-order.md) covers the v1 caveat.
Values equal under `==` have identical bytes by definition, so the byte form carries no
provenance: a parsed UUID and a `new(bytes)` one store and compare the same.
