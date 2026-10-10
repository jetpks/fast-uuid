# How to generate deterministic UUIDs for tests

Two different kinds of determinism. `v7(time:)` pins a UUID's timestamp so a test can
assert on it. `v3` and `v5` go further: the same namespace and name give the same UUID
in every process, on every machine, at any time — nothing is random at all.

## Pin a v7 to an exact millisecond

Make a v7 UUID that a test can assert on: same injected time, same leading twelve hex
digits, every run. You need `Fast::UUID.v7` and a `Time`.

### Steps

1. Inject the time. `v7` takes any `Time` and truncates it to whole milliseconds for
   the 48-bit `unix_ts_ms` field:

   ```ruby
   uuid = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 12, 0, 0))
   uuid.hex[0, 12] # => "018d0cfe2a00", the unix_ts_ms in hex
   ```

   The value is pinned to the millisecond, so the assertion is stable whatever the clock
   did between runs. (`Fast::UUID.v4` takes no time; it is random by construction.)

2. Read the time back out instead of duplicating the constant. `timestamp` returns the
   UTC `Time` the leading bytes encode:

   ```ruby
   uuid.timestamp == Time.utc(2024, 1, 15, 12, 0, 0) # => true
   ```

3. For a whole collection, inject increasing times and the sort order follows:

   ```ruby
   base = Time.utc(2024, 1, 15, 12, 0, 0)
   ids = 3.times.map { |i| Fast::UUID.v7(time: base + i) }
   ids.sort == ids # => true, byte order is time order for v7
   ```

## Derive a UUID from a name

`v3` and `v5` hash a namespace and a name into the UUID: the same input is the same
UUID, across processes, machines and time. There is nothing random and nothing to pin.

### Steps

1. Prefer v5. Both versions hash the same input — the namespace's 16 bytes followed by
   the name's — but v5 uses SHA-1 where v3 uses MD5, and the RFC recommends v5 where
   possible.

   ```ruby
   uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
   uuid.to_s # => "2ed6657d-e927-568b-95e1-2665a8aea6a2", on every machine, forever
   ```

2. The namespace is a `Fast::UUID` or a canonical String; the name is any String, its
   bytes hashed as they are. `NAMESPACE_DNS`, `NAMESPACE_URL`, `NAMESPACE_OID` and
   `NAMESPACE_X500` are the RFC §6.6 well-known namespaces; a namespace of your own is
   any UUID you fix once and never regenerate.

   ```ruby
   Fast::UUID.v5("6ba7b810-9dad-11d1-80b4-00c04fd430c8", "www.example.com") == uuid
   # => true, the String goes through parse
   ```

3. Same input, same UUID — which is the point. A fixture built this way is repeated,
   not merely reproducible: every bit is a function of the input, and the version
   nibble and variant are the only fields the hash does not fill.

## Notes

For v7, only the timestamp is deterministic. The remaining 74 bits stay random on every
call, so two UUIDs made with the same `time:` are never equal — the fixture is
reproducible, not repeated. That is the RFC's default v7 shape: counters are optional
and none is kept, which is also why generation is thread-safe. See
[Why validity is the grammar and nothing more](../explanation/validity.md) and
[In what order UUIDs sort](../explanation/comparison-order.md) for the facts behind
both behaviours.
