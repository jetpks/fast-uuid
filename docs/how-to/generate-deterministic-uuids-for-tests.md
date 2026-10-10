# How to generate deterministic UUIDs for tests

Make a v7 UUID that a test can assert on: same injected time, same leading twelve hex
digits, every run. You need `Fast::UUID.v7` and a `Time`.

## Steps

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

## Notes

Only the timestamp is deterministic. The remaining 74 bits stay random on every call,
so two UUIDs made with the same `time:` are never equal — the fixture is reproducible,
not repeated. That is the RFC's default v7 shape: counters are optional and none is
kept, which is also why generation is thread-safe. See
[Why validity is the grammar and nothing more](../explanation/validity.md) and
[In what order UUIDs sort](../explanation/comparison-order.md) for the facts behind
both behaviours.
