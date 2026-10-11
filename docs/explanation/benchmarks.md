# Benchmarks

I couldn't call this fast-uuid without benchmarks.

Benchmarks are `Fast::UUID` against `SecureRandom`'s generation and
`uuidtools`'s parsing. Ruby 4.0.7, single process, Apple M4 Max
(arm64-darwin23).

To measure speed, each competing operation runs under `benchmark-ips` for 5s
with a 1s warmup. To measure allocations, each operation is called 10
thousand times with GC disabled and `GC.stat(:total_allocated_objects)` read
before & after each call.

The sample UUID used for parsing the parsing benchmark is a v7 UUID from
Appendix A of RFC 9562[^1].

## Results

| operation | i/s | ±% | objects/call |
|---|---|---|---|
| Fast::UUID.uuid_v4 => String | 719,478 | 0.43 | 2.00 |
| SecureRandom.uuid_v4 => String | 641,804 | 0.48 | 8.00 |
| Fast::UUID.uuid_v7 => String | 636,803 | 0.41 | 4.00 |
| SecureRandom.uuid_v7 => String | 648,711 | 0.35 | 10.00 |
| Fast::UUID.v7 => Fast::UUID | 584,269 | 0.44 | 6.00 |
| Fast::UUID.v4 => Fast::UUID | 652,554 | 0.38 | 4.00 |
| Fast::UUID.parse | 1,138,533 | 0.48 | 6.00 |
| UUIDTools::UUID.parse | 424,056 | 0.66 | 27.00 |

`Fast::UUID` provides drop-in replacements for `SecureRandom` methods `uuid_v4`
and `uuid_v7`, which both return Strings. The Fast::UUID uuid_v4 variant is 12%
faster, and allocates 75% fewer objects. The Fast::UUID uuid_v7 variant is 2%
slower, but allocates 60% fewer objects.

`Fast::UUID.v4` and `Fast::UUID.v7` return Fast::UUID objects that can be
used in place of Strings in most cases.

## Reproducing

```bash
BENCH_QUICK=1 bundle exec ruby benchmark/uuid.rb   # half-second samples, seconds total
bundle exec ruby benchmark/uuid.rb                 # five-second samples, about a minute
```

Both print the `RUBY_DESCRIPTION` and the fast-uuid version, then the eight rows in the
shape of the table above. Numbers move between machines, Ruby versions and runs; treat
the ratios as the finding and re-measure before quoting anything finer.


[^1]: RFC 9562, Appendix A — <https://www.rfc-editor.org/rfc/rfc9562#appendix-a>
