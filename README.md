# fast-uuid

> **Alpha, pre-1.0.** The API surface may still move between v0.x and v1.0.

RFC 9562 UUIDs for Ruby, pure Ruby with nothing on top of them: generate v4
and v7 — as frozen value objects or as bare Strings (`Fast::UUID.uuid`,
`uuid_v4`…`uuid_v7`) — the time-based v1 and v6, derive deterministic v3 and
v5 from a namespace and a name, parse and validate every version and variant,
and compare UUIDs as the opaque 128-bit values they are.

A UUID is not a sha256sum. A digest is an opaque checksum *of* content; a UUID is an
identifier you *construct* with chosen properties. v1 and v6 embed a 60-bit Gregorian
timestamp and v7 a 48-bit Unix one — `#timestamp` reads it back. v6 and v7 sort
chronologically as raw bytes, so a column of them is a timeline its index maintains for
free. v3 and v5 derive deterministically from a namespace and a name: same input, same
UUID, across processes, machines and years, with no storage. And v4 is 122 bits of
CSPRNG when opaque randomness is the point. [Why a UUID is not a
sha256sum](docs/explanation/uuid-versions.md) is the tour of what that buys you.

The goal is a nice, fast, consistent interface that covers everything you
might want to do with a UUID: the RFC end-to-end, zero dependencies, proven
in-suite against the RFC's own Appendix A test vectors. The established
options each cover part of that surface — `securerandom` ships `uuid_v4` and
`uuid_v7` as Strings, `uuidtools` covers parsing and most of the versions,
`uuid` is archived — and fast-uuid brings the whole of it under one interface.

## Installation

```ruby
gem "fast-uuid"
```

`require "fast/uuid"` has no dependencies.

## Quickstart

```ruby
require "fast/uuid"

uuid = Fast::UUID.generate            # v7, the RFC's recommended default
Fast::UUID.uuid_v4                    # => "b4c7b0f1-…", or uuid_v1…uuid_v7 — the object twins' canonical String, object skipped
Fast::UUID.parse(uuid.to_s) == uuid   # => true, from any conforming String, any case
Fast::UUID.v4.version                 # => 4
Fast::UUID.v7.timestamp               # => a UTC Time, the 48-bit unix_ts_ms
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com").to_s
                                      # => "2ed6657d-e927-568b-95e1-2665a8aea6a2", same input, same UUID

sorted = [Fast::UUID.v7, Fast::UUID.v7].sort  # v7 sorts chronologically, RFC 6.11
```

`Fast::UUID.parse` raises `Fast::UUID::ParseError` for anything the RFC 4
grammar rejects and `TypeError` for an object with no `to_s`; `parse?` and `valid?` are
the non-raising forms. Validity is the grammar and nothing more — every
version and variant parses, Nil and Max included.

One caveat the RFC does not decide for you: opaque byte order makes v6 and
v7 sort chronologically, but **v1 does not** — its `time_low` field sits
first in the byte string, so v1 UUIDs sort in a scrambled order. The
[tutorial](docs/tutorials/generate-parse-and-sort-uuids.md) walks the whole
story: generate, parse, introspect, sort, and a request-ID module at the end
of it.

## Performance

Measured on the six operations the gem and its references share — generation
against `securerandom`, parsing against `uuidtools` (Ruby 4.0.7; conditions,
the allocation columns and how to reproduce on the
[benchmarks page](docs/explanation/benchmarks.md)):

- Generation is **ahead of the stdlib String for v4, within 8% for v7** —
  0.77M vs 0.74M i/s for v4, 0.69M vs 0.75M for v7, at half or fewer of the
  objects — and the String forms win outright: `uuid_v4` 0.83M vs 0.74M with a
  quarter of the objects, `uuid_v7` 0.73M vs 0.75M with two fifths.
- Parsing is **3x faster than uuidtools with 4.5x fewer objects** — 1.49M vs
  0.48M i/s, 6 objects per call against 27 — because it is a grammar check and
  one `pack`, not a decoded field graph.

## Documentation

### Tutorials

- [Tutorial: generate, parse and sort UUIDs](docs/tutorials/generate-parse-and-sort-uuids.md) — generate, parse, introspect and sort, ending in a sortable request ID.

### How-to guides

- [How to choose a UUID version](docs/how-to/choose-a-uuid-version.md) — v7 by default, v6 for a v1 fleet, v5 for name-derived determinism, v4 for randomness, v1 for legacy systems.
- [How to generate deterministic UUIDs for tests](docs/how-to/generate-deterministic-uuids-for-tests.md) — pin a v7 to an exact millisecond with `v7(time:)`, pin a v1 or v6 to the 100-ns tick, or derive a stable v5 from a namespace and name.
- [How to validate untrusted input](docs/how-to/validate-untrusted-input.md) — what `parse?` and `valid?` return, and what `parse` raises.
- [How to sort UUIDs correctly](docs/how-to/sort-uuids-correctly.md) — `<=>` byte order, and the v1 caveat.
- [How to store a UUID as 16 bytes](docs/how-to/store-a-uuid-as-16-bytes.md) — `bytes` out, `new(bytes)` back.

### Reference

- [Reference: Fast::UUID](docs/reference/uuid.md) — every class method, instance method, constant and error.

### Explanation

- [Why a UUID is not a sha256sum](docs/explanation/uuid-versions.md) — the versions explained: embedded time, natural sorting, name-derived determinism, and randomness as one option among five.
- [Why validity is the grammar and nothing more](docs/explanation/validity.md) — why no version or variant gate: the RFC defines none, and Nil and Max sit outside the 10xx variant by design.
- [In what order UUIDs sort](docs/explanation/comparison-order.md) — opaque bytes per RFC §6.11, v6/v7 chronological, v1 anti-chronological.
- [Benchmarks](docs/explanation/benchmarks.md) — generation against securerandom, parsing against uuidtools, and how to reproduce them.

## Development

```bash
bundle exec sus
bundle exec rubocop
bundle exec ruby benchmark/uuid.rb                 # full run, about a minute
BENCH_QUICK=1 bundle exec ruby benchmark/uuid.rb   # quick run, seconds
```
