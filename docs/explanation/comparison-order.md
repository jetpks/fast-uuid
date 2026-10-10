# In what order UUIDs sort

`Fast::UUID` includes `Comparable`, and `#<=>` compares two UUIDs as unsigned 128-bit
integers — the raw bytes, nothing else. This page is why that is the right default and
what it does and doesn't buy you.

## What the RFC says

RFC 9562 §6.11: UUIDs v6 and v7 are "designed so that as opaque raw bytes, ignoring the
version and variant bits, they lexicographically sort with respect to their creation
time". §6.13 adds the practical consequence: store them as 128-bit binary where
feasible, and the index sorts them for you.

The design lives in the byte layouts. A v7 UUID begins with 48 bits of `unix_ts_ms`, so
the leading bytes are the timestamp and byte order is time order to the millisecond; a
v6 UUID carries the same 60-bit Gregorian timestamp as a v1 but reordered
big-endian-first (`time_high`, then `time_mid`, then `time_low`), which is exactly the
fix for the caveat below. [What a UUID is, and what its versions are](uuid-versions.md)
is the tour of what each version embeds; this page is the ordering consequence.

## The v1 caveat

A v1 UUID (§5.1) splits its 60-bit timestamp into `time_low` (the least significant 32
bits), `time_mid`, and `time_high` — and writes `time_low` first in the byte string.
Sorted as raw bytes, v1 UUIDs order by `time_low` first: within one `time_mid` period
— a stretch of about seven minutes — `time_low` still increases with time, but at
every boundary where it wraps back to zero, an earlier UUID sorts after a later one.
v1 is time-based but breaks chronology under byte order at every `time_mid` boundary,
and no comparison function can fix that without stopping being opaque.

This is why the RFC's guidance is about v6 and v7 and says nothing about v1.

## What the comparison compares

Everything else is value, in the plainest sense: `#<=>` looks at all 128 bits,
including the version and variant nibbles. Consequences worth knowing:

- `Fast::UUID::NIL` sorts before every other UUID and `Fast::UUID::MAX` after, as all
  zeros and all ones must.
- A mixed-version collection sorts by value, not by time: a v3 with large leading bytes
  sorts after a v7 made years later.
- Two UUIDs of any version with equal bytes are equal — `==` and `<=>` see the same
  thing.

If what you need is time order across versions, sort by `timestamp` instead; for a
single version's worth of v6 or v7, `<=>` already is that sort. The how-to
[How to sort UUIDs](../how-to/sort-uuids-correctly.md) shows both.
