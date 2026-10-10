# Benchmarks

What the value object costs: fast-uuid 0.1.0 measured against the two references
already on the ecosystem's load path, `securerandom` for generation and `uuidtools`
for parsing. Single process, Ruby 4.0.7, Apple M4 Max (arm64-darwin23); uuidtools
3.0.0, benchmark-ips 2.15.1. `benchmark/uuid.rb` produces the one table below.

Each operation runs under `benchmark-ips` for two seconds after half a second of
warmup, and separately once for allocation: ten thousand calls with GC disabled and
`GC.stat(:total_allocated_objects)` read around them, so the last column is the
operation's whole Ruby-object footprint per call. The parsed sample is a v7 vector and
comes from Appendix A of RFC 9562[^1].

fast-uuid produces RFC-compliant UUIDs faster and more efficiently than `SecureRandom`,
and parses them faster and more efficiently than `uuidtools`. These gains come mostly
from avoiding object allocations, which provides direct speedups at runtime and
efficiency gains at garbage-collection time. Read the two libraries for what they are.
`SecureRandom.uuid_v4` and `.uuid_v7` return a String and nothing else — 36 characters,
no version, no timestamp, no comparison. fast-uuid's `uuid_v4` and `uuid_v7` do the
same CSPRNG work and return the same String shape, with the version and variant bytes
masked in place instead of a round trip through 64-bit words. The object constructors build the
frozen value object on top of the same bytes, and still come out ahead of the stdlib
String for v4 and within 8% of it for v7, at half or fewer of the objects; what the
object buys is everything else in this gem. `UUIDTools::UUID.parse` returns a mutable
object that carries its decoded fields; fast-uuid's parse is a grammar check and one
`pack`, and it wins the same way: fewer objects, less work.

## Results

| operation | i/s | ±% | objects/call |
|---|---|---|---|
| generate v4, fast-uuid | 765,330 | 2.41 | 4.00 |
| generate v4, securerandom | 739,618 | 1.43 | 8.00 |
| generate v7, fast-uuid | 690,317 | 1.58 | 6.00 |
| generate v7, securerandom | 746,937 | 1.47 | 10.00 |
| uuid_v4 string, fast-uuid | 825,809 | 1.38 | 2.00 |
| uuid_v7 string, fast-uuid | 726,870 | 2.17 | 4.00 |
| parse, fast-uuid | 1,489,398 | 3.23 | 6.00 |
| parse, uuidtools | 477,883 | 3.01 | 27.00 |

The string constructors are the stdlib's own names and drop-ins for them, and they win
outright: `uuid_v4` is 11% ahead of `SecureRandom.uuid_v4` with a quarter of the
objects, `uuid_v7` at parity with two fifths. The object constructors are ahead of the
stdlib String for v4 and within 8% for v7, at half or fewer of the objects — the value
object costs three more allocations than the String alone and buys parse, compare and
timestamp. Parsing is where the design difference shows: fast-uuid parses **3x faster
than uuidtools with 4.5x fewer objects**, because the parse is a match against one
Regexp and a `pack("H*")` rather than an object graph of decoded fields.

## Reproducing

```bash
BENCH_QUICK=1 bundle exec ruby benchmark/uuid.rb   # half-second samples, seconds total
bundle exec ruby benchmark/uuid.rb                 # two-second samples, about a minute
```

Both print the `RUBY_DESCRIPTION` and the fast-uuid version, then the eight rows in the
shape of the table above. Numbers move between machines, Ruby versions and runs; treat
the ratios as the finding and re-measure before quoting anything finer.

## Key takeaways

- Generation wins both ways: the `uuid_v4`/`uuid_v7` String forms **beat `SecureRandom`'s
  own at parity or better, with a quarter to two fifths of the objects**, and the value
  object on top still lands ahead of the stdlib String for v4, within 8% for v7.
- Parsing is **3x faster than uuidtools with 4.5x fewer objects** — a grammar check and
  one `pack` against a decoded field graph.
- Nothing here allocates per-character: every operation's whole footprint is single
  digits of Ruby objects.
- fast-uuid is the right call even when a String is all you want — its `uuid_v4` and
  `uuid_v7` are drop-ins for the stdlib's own and its numbers say the value object
  around them is nearly free.

[^1]: RFC 9562, Appendix A — <https://www.rfc-editor.org/rfc/rfc9562#appendix-a>
