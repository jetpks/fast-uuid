# How to sort UUIDs correctly

Put UUIDs in order with `<=>`, and know when that order is the creation order you
probably wanted. You need an Array of `Fast::UUID` values — or of anything that stores
them.

## Steps

1. Sort with the default comparison. `Fast::UUID` includes `Comparable`, and `#<=>`
   compares the two 128-bit values as unsigned bytes:

   ```ruby
   max   = Fast::UUID::MAX
   nil_  = Fast::UUID::NIL
   v7    = Fast::UUID.v7
   [v7, max, nil_].sort
   # => [nil_, v7, max], the bits decide: all zeros, anything, all ones
   ```

2. Prefer v7 (or v6) when the order should be a timeline. Their timestamp sits in the
   leading bytes, so byte order is time order — RFC 9562 §6.11 says they are designed
   to sort as raw bytes:

   ```ruby
   base = Time.utc(2024, 1, 15, 12, 0, 0)
   ids = 3.times.map { |i| Fast::UUID.v7(time: base + i) }
   ids.sort == ids # => true
   ```

   This is why v7 keys sort well in a database: a `bytes` column of v7 UUIDs is
   chronologically clustered by construction. See
   [How to store a UUID as 16 bytes](store-a-uuid-as-16-bytes.md).

3. Do not mix v1 in and expect time order. v1 is time-based too, but its `time_low`
   field sits first in the byte string, so its byte order scrambles its time order:

   ```ruby
   v1_a = Fast::UUID.parse("C232AB00-9414-11EC-B3C8-9F6BDECED846")
   v1_b = Fast::UUID.parse("C232AB01-9414-11EC-B3C8-9F6BDECED846")
   (v1_a <=> v1_b) # => -1, but the low word decides, not the timestamp
   ```

## Notes

The comparison is opaque by design: the RFC treats the 128 bits as bits, and
[In what order UUIDs sort](../explanation/comparison-order.md) explains what follows.
Why v6 and v7 embed their time where they do — and what else the versions buy — is
[What a UUID is, and what its versions are](../explanation/uuid-versions.md).
One consequence worth knowing: sorting a mixed collection sorts by value, not by
version or time, so a v3 can sort before a v7 that was made years earlier. If you need
time order across versions, sort by `timestamp` — but for one version's worth of v6 or
v7, `<=>` already is that sort.
