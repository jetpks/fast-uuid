# Benchmarks

I couldn't call this fast-uuid without benchmarks.

Benchmarks are `Fast::UUID` against `SecureRandom`'s generation and
`uuidtools`'s parsing. Ruby 4.0.7, single process, Apple M4 Max
(arm64-darwin23).

To measure speed, each competing operation runs under `benchmark-ips` for 2s
with a 0.5s warmup. To measure allocations, each operation is called 10
thousand times with GC disabled and `GC.stat(:total_allocated_objects)` read
before & after each call.

The sample UUID used for parsing the parsing benchmark is a v7 UUID from
Appendix A of RFC 9562[^1].

## Results

| operation | i/s | ±% | objects/call |
|---|---|---|---|
| Fast::UUID.uuid_v4 => String | 723,059 | 0.38 | 2.00 |
| SecureRandom.uuid_v4 => String | 636,947 | 0.45 | 8.00 |
| Fast::UUID.uuid_v7 => String | 641,885 | 0.33 | 4.00 |
| SecureRandom.uuid_v7 => String | 649,131 | 0.50 | 10.00 |
| Fast::UUID.v7 => Fast::UUID | 587,187 | 0.39 | 6.00 |
| Fast::UUID.v4 => Fast::UUID | 658,510 | 0.47 | 4.00 |
| Fast::UUID.parse | 1,148,483 | 0.52 | 6.00 |
| UUIDTools::UUID.parse | 422,767 | 0.92 | 27.00 |

`Fast::UUID` provides drop-in replacements for `SecureRandom` methods `uuid_v4`
and `uuid_v7`, which return Strings. The `Fast::UUID` variants are faster and
allocate fewer objects with no compromise on randomness.

`Fast::UUID.v4` and `Fast::UUID.v7` return Fast::UUID objects that can be
used in place of Strings in most cases.

## Reproducing

```bash
BENCH_QUICK=1 bundle exec ruby benchmark/uuid.rb   # half-second samples, seconds total
bundle exec ruby benchmark/uuid.rb                 # two-second samples, about a minute
```

Both print the `RUBY_DESCRIPTION` and the fast-uuid version, then the eight rows in the
shape of the table above. Numbers move between machines, Ruby versions and runs; treat
the ratios as the finding and re-measure before quoting anything finer.


[^1]: RFC 9562, Appendix A — <https://www.rfc-editor.org/rfc/rfc9562#appendix-a>
