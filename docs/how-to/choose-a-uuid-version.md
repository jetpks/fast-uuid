# How to choose a UUID version

You need an identifier, and the RFC offers six versions. Pick by the property the
identifier must have — the version nibble is the property's name. Every branch below
is one call and a link to the piece that goes deeper.

## Steps

1. **Need an ID, full stop: v7.** It is the RFC's recommended default and the gem's —
   embedded millisecond time, sorts by creation time, a fully random tail:

   ```ruby
   Fast::UUID.generate # => a v7; Fast::UUID.uuid for the String alone
   ```

   [The tutorial](../tutorials/generate-parse-and-sort-uuids.md) starts here and
   develops the whole surface.

2. **Need identifiers that sort in creation order in a key or column: v7.** The
   timestamp sits in the leading bytes, so opaque byte order is chronological order
   (RFC 9562 §6.11), and a 16-byte `bytes` column is chronologically clustered by
   construction (§6.13):

   ```ruby
   Fast::UUID.v7 # => the current Unix time leads the bytes
   ```

   [How to sort UUIDs](sort-uuids-correctly.md) and
   [How to store a UUID as 16 bytes](store-a-uuid-as-16-bytes.md) cover the key and
   the column. Migrating a fleet that already issues v1? **v6** is v1's timestamp
   reordered most-significant-first — the same node, clock sequence and 100-ns
   resolution, but byte order that sorts.

3. **Need the same input to give the same ID, with nothing stored: v5.** A namespace
   and a name hash to the same UUID in every process, on every machine, at any time:

   ```ruby
   Fast::UUID.v5(Fast::UUID::NAMESPACE_URL, "https://example.com/docs")
   # => same input, same UUID — no storage, no coordination
   ```

   [How to generate deterministic UUIDs](generate-deterministic-uuids-for-tests.md)
   shows the fixture and the injection variants. **v3** is the same construction with
   MD5; choose it only to interoperate with a system that already issues v3.

4. **Need only uniqueness, nothing else: v4.** 122 CSPRNG bits, no time, no name, no
   order:

   ```ruby
   Fast::UUID.v4 # => 122 random bits, version and variant stamped in
   ```

5. **Talking to a system that already issues v1: v1.** Generate to match it —
   `time:`, `node:` and `clock_sequence:` are injectable — but never sort v1 by its
   bytes: its timestamp is split least-significant-first, so byte order is not time
   order ([In what order UUIDs sort](../explanation/comparison-order.md)).

   ```ruby
   Fast::UUID.v1 # => the Gregorian ancestor; generate only at a v1 boundary
   ```

## Notes

The decision in one line: **v7 unless you need determinism (v5) or nothing but
uniqueness (v4); v6 and v1 only at a v1 boundary.** The why — what each version's
structure buys, and why a UUID is not a sha256sum — is
[What a UUID is, and what its versions are](../explanation/uuid-versions.md).
