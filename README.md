# fast-uuid

RFC 9562 UUIDs for Ruby, pure Ruby with nothing on top of them: generate v4
and v7, parse and validate every version and variant, and compare UUIDs as
the opaque 128-bit values they are.

It is not a replacement for anything already on your load path, because
there is nothing there to replace. `securerandom` ships `uuid_v4` and
`uuid_v7`, but they only ever hand you a String — no value object, no parse,
no compare, no timestamp. `uuid` is archived, v1-only, last released in 2018.
`uuidtools` validates but does not generate v6, v7 or v8. fast-uuid covers
the RFC end-to-end, zero dependencies, proven in-suite against the RFC's own
Appendix A test vectors.

## Installation

```ruby
gem "fast-uuid"
```

`require "fast/uuid"` has no dependencies.

## Quickstart

```ruby
require "fast/uuid"

uuid = Fast::UUID.generate            # v7, the RFC's recommended default
Fast::UUID.parse(uuid.to_s) == uuid   # => true, from any conforming String, any case
Fast::UUID.v4.version                 # => 4
Fast::UUID.v7.timestamp               # => a UTC Time, the 48-bit unix_ts_ms

sorted = [Fast::UUID.v7, Fast::UUID.v7].sort  # v7 sorts chronologically, RFC 6.11
```

`Fast::UUID.parse` raises `Fast::UUID::ParseError` for anything the RFC 4
grammar rejects and `TypeError` for a non-String; `parse?` and `valid?` are
the non-raising forms. Validity is the grammar and nothing more — every
version and variant parses, Nil and Max included.

One caveat the RFC does not decide for you: opaque byte order makes v6 and
v7 sort chronologically, but **v1 does not** — its `time_low` field sits
first in the byte string, so v1 UUIDs sort in a scrambled order.

## Development

```bash
bundle exec sus
bundle exec rubocop
BENCH_QUICK=1 bundle exec ruby benchmark/uuid.rb   # generation and parsing against securerandom and uuidtools
```
