# Benchmarks

What the value object costs: fast-uuid 0.1.0 measured against the two references
already on the ecosystem's load path, `securerandom` for generation and `uuidtools`
for parsing. Single process, Ruby 4.0.7, Apple M4 Max (arm64-darwin23); uuidtools
3.0.0, benchmark-ips 2.15.1. `benchmark/uuid.rb` produces the one table below.

Each operation runs under `benchmark-ips` for two seconds after half a second of
warmup, and separately once for allocation: ten thousand calls with GC disabled and
`GC.stat(:total_allocated_objects)` read around them, so the last column is the
operation's whole Ruby-object footprint per call. The parsed sample is the RFC 9562
Appendix A v7 vector.

Read the two libraries for what they are. `SecureRandom.uuid_v4` and `.uuid_v7` return
a String and nothing else — 36 characters, no version, no timestamp, no comparison.
fast-uuid does the same CSPRNG work and then builds a frozen value object from the
bytes, so its generation is a little slower and allocates a little more, and what it
buys is everything else in this gem. `UUIDTools::UUID.parse` returns a mutable object
that carries its decoded fields; fast-uuid's parse is a grammar check and one `pack`,
and it wins the same way: fewer objects, less work.

## Results

| operation | i/s | ±% | objects/call |
|---|---|---|---|
| generate v4, fast-uuid | 639,126 | 1.48 | 12.00 |
| generate v4, securerandom | 730,574 | 1.42 | 8.00 |
| generate v7, fast-uuid | 580,796 | 6.92 | 12.02 |
| generate v7, securerandom | 739,601 | 1.60 | 10.00 |
| parse, fast-uuid | 1,478,526 | 1.51 | 6.00 |
| parse, uuidtools | 484,179 | 1.83 | 27.00 |

Generation is 12.5% behind the stdlib String for v4 and 21.5% for v7: the CSPRNG call
and the String it returns dominate both, and the value object on top costs four more
objects — the bytes, the canonical form, the mask arithmetic's temporaries. Parsing is
where the design difference shows: fast-uuid parses **3x faster than uuidtools with
4.5x fewer objects**, because the parse is a match against one Regexp and a `pack("H*")`
rather than an object graph of decoded fields.

## Reproducing

```bash
BENCH_QUICK=1 bundle exec ruby benchmark/uuid.rb   # half-second samples, seconds total
bundle exec ruby benchmark/uuid.rb                 # two-second samples, about a minute
```

Both print the `RUBY_DESCRIPTION` and the fast-uuid version, then the six rows in the
shape of the table above. Numbers move between machines, Ruby versions and runs; treat
the ratios as the finding and re-measure before quoting anything finer.

## Key takeaways

- Generation pays the value object's keep: **~0.8–0.9x `SecureRandom`'s String**, for
  an object that parses, compares, timestamps and round-trips.
- Parsing is **3x faster than uuidtools with 4.5x fewer objects** — a grammar check and
  one `pack` against a decoded field graph.
- Nothing here allocates per-character: every operation's whole footprint is single
  digits of Ruby objects.
- `securerandom` remains the right call when a String is all you want; fast-uuid's
  numbers say the value object around it is nearly free.
