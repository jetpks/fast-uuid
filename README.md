# fast-uuid

> **Status:** _Alpha, pre-1.0_ The API surface may still move between v0.x and v1.0.

A UUID library for Ruby that is fast, complete, and RFC 9562-compliant.

Fast::UUID provides drop-in, api-compatible replacements for `SecureRandom`'s `.uuid_v4` and `.uuid_v7` that are as fast (within 2%) or faster while allocating half as many objects or fewer while using the same source of entropy.

```ruby
# before
SecureRandom.uuid_v4   # => "cdbb6d1f-…"
SecureRandom.uuid_v7   # => "01a12861-…"

# after — the same calls, the same entropy, frozen, half the objects or fewer
Fast::UUID.uuid_v4     # => "e74ce176-…"
Fast::UUID.uuid_v7     # => "01a12861-…"
```

Fast::UUID can also return immutable `Fast::UUID` objects that are directly `Comparable`. These also allocate fewer objects than `SecureRandom`'s `.uuid_v4` and `.uuid_v7`.

```ruby
a = Fast::UUID.v7(time: Time.utc(2026, 10, 10))
b = Fast::UUID.v7(time: Time.utc(2026, 10, 11))
a < b                          # => true — v7 byte order is time order
[a, b].max.timestamp           # => 2026-10-11 00:00:00 UTC
Fast::UUID.parse(a.to_s) == a  # => true — identity is the 128-bit value alone
```

Fast::UUID's goal is to cover every UUID use-case a project could have in a way that is correct and of course, fast.

## Installation

Add to your Gemfile:

```ruby
gem "fast-uuid"
```
and `require "fast/uuid"`.

Fast::UUID has no dependencies and is implemented in pure Ruby.

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

- Generation is **ahead of the stdlib String for v4, within 10% for v7** —
  0.65M vs 0.64M i/s for v4, 0.58M vs 0.65M for v7, at half or fewer of the
  objects — and the String forms win outright: `uuid_v4` 0.72M vs 0.64M with a
  quarter of the objects, `uuid_v7` 0.64M vs 0.65M — parity — with two fifths.
- Parsing is **2.7x faster than uuidtools with 4.5x fewer objects** — 1.14M vs
  0.42M i/s, 6 objects per call against 27 — because it is a grammar check and
  one `pack`, not a decoded field graph.

## Documentation

### Tutorials

- [Tutorial: generate, parse and sort UUIDs](docs/tutorials/generate-parse-and-sort-uuids.md) — generate, parse, introspect and sort, ending in a sortable request ID.

### How-to guides

- [How to choose a UUID version](docs/how-to/choose-a-uuid-version.md) — v7 by default, v6 for a v1 fleet, v5 for name-derived determinism, v4 for randomness, v1 for legacy systems.
- [How to generate deterministic UUIDs](docs/how-to/generate-deterministic-uuids.md) — pin a v7 to an exact millisecond with `v7(time:)`, pin a v1 or v6 to the 100-ns tick, or derive a stable v5 from a namespace and name.
- [How to validate untrusted input](docs/how-to/validate-untrusted-input.md) — what `parse?` and `valid?` return, and what `parse` raises.
- [How to sort UUIDs](docs/how-to/sort-uuids.md) — `<=>` byte order, and the v1 caveat.
- [How to store a UUID as 16 bytes](docs/how-to/store-a-uuid-as-16-bytes.md) — `bytes` out, `new(bytes)` back.

### Reference

- [Reference: Fast::UUID](docs/reference/uuid.md) — every class method, instance method, constant and error.

### Explanation

- [What a UUID is, and what its versions are](docs/explanation/uuid-versions.md) — embedded time, natural sorting, name-derived determinism, and randomness as one option among five.
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
