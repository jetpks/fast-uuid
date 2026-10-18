# Performance and allocations

## How these numbers were measured

The table below was produced by:

```sh
LC_ALL=en_US.UTF-8 bundle exec ruby benchmark/uuid.rb
```

Ruby version from the benchmark's first output line:

```text
ruby 4.0.7 (2026-09-15 revision 229531a6cf) +PRISM [arm64-darwin23]; fast-uuid 0.1.0
```

- Gem floor Ruby `>= 3.3` (`fast-uuid.gemspec:15`), CI matrix 3.3 / 3.4 / 4.0, test framework `sus`.
- `benchmark-ips` 2.15.1 (`gems.locked`).
- Full mode: 5 s measure / 1 s warmup per operation (`benchmark/uuid.rb:47`). Quick mode (`BENCH_QUICK=1`) is 0.5 s measure / 0.2 s warmup and is not used for published numbers.
- `uuidtools`, `securerandom`, and `benchmark-ips` are dev-only comparison references, never runtime dependencies (`gems.rb`).
- Objects per call is measured with GC disabled over 10,000 settled calls: one warm call, `GC.start`, `GC.disable`, delta of `GC.stat(:total_allocated_objects)` over the batch, `GC.enable` in `ensure` (`benchmark/uuid.rb:18-28`). GC-disabled counting measures allocation, not retention.
- Results vary run-to-run (see the `±%` column, which is `benchmark-ips`' own error estimate: `entry.stats.error / entry.ips * 100`) and machine-to-machine. The table is an observation, not a guarantee.

## Throughput

```text
ruby 4.0.7 (2026-09-15 revision 229531a6cf) +PRISM [arm64-darwin23]; fast-uuid 0.1.0
| operation | i/s | ±% | objects/call |
|---|---|---|---|
| Fast::UUID.uuid_v4 => String | 791,257 | 4.92 | 2.00 |
| SecureRandom.uuid_v4 => String | 724,529 | 2.68 | 8.00 |
| Fast::UUID.uuid_v7 => String | 727,567 | 1.52 | 4.00 |
| SecureRandom.uuid_v7 => String | 734,428 | 2.30 | 10.00 |
| Fast::UUID.v7 => Fast::UUID | 665,153 | 1.87 | 6.00 |
| Fast::UUID.v4 => Fast::UUID | 744,876 | 1.68 | 4.00 |
| Fast::UUID.parse | 1,291,207 | 1.96 | 6.00 |
| UUIDTools::UUID.parse | 477,999 | 1.81 | 27.00 |
```

Eight rows, labels exactly as in the operations hash (`benchmark/uuid.rb:32-41`). `i/s` is comma-grouped and rounded; `±%` is the `benchmark-ips` error estimate; `objects/call` is the GC-disabled allocation count above. No derived speedup ratios are stated beyond the copied table.

## Objects per call

The `objects/call` column above is the measured allocation cost per settled call. Tests pin the same counts as strict budgets on Ruby 4.0.7 (`test/fast/uuid/allocations.rb:5-13`, averaged over 100 runs) — these are the budgets the docs may state, cited to the test file:

- `parse` 6
- `v4` 4
- `v7` 6
- `uuid_v4` 2
- `uuid_v7` 4
- `v6` 9
- `v3` 8 (Symbol name 7)
- `v5` 9 (Symbol name 8)
- `to_s` 0, `hex`/`urn` 1, `==`/`<=>`/`hash` 0, `v7` `#timestamp` 2

v1 is clock-phase dependent: its `time_low` word crosses the immediate-Integer line whenever its top bits are set, a phase cycling every few minutes. 13 objects is the high phase and the low phase costs four fewer (9). The test pins only `< 14` and the header budget was frozen as 9 on Ruby 4.0.7:

```ruby
# test/fast/uuid/allocations.rb:58-63
# 13 is the high phase; the low phase costs four fewer (9). The test pins only < 14.
```

The benchmark's live counts and the test-suite budgets are distinct — the budgets are pinned by the test suite on a fixed Ruby version, the benchmark's fourth column is a live measurement on the running Ruby. Counts are version-specific because immediate-Integer and Flonum ranges differ across Ruby versions.

## Why it is cheap

- `to_s` is precomputed and frozen at construction — no allocation on read.
- `stamp` uses `setbyte` arithmetic — zero objects for version and variant stamping.
- `canonical` uses `Digest.hexencode` and in-place `insert` with `freeze`.

Parse's six objects are named in the test's own comment at `test/fast/uuid/allocations.rb:24-30`: the dehyphenated text, the packed bytes, the binary copy, the hex, and the canonical form.

For the full API and layout context, see [Fast::UUID — API reference](../reference/fast-uuid.md) and [How the versions and variants are laid out](version-variant-layout.md).
