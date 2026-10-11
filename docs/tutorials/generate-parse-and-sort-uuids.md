# Tutorial: generate, parse and sort UUIDs

In this tutorial we generate UUIDs with fast-uuid — randomly, from the clock, and from
names — parse one from the outside world, read what it tells us about itself, and sort
a collection of them. By the end you'll have a small request-ID module: identifiers
that sort by creation time, validate untrusted input, come back out of storage as the
same value, and derive stably from a name when nothing should be stored.

You'll need Ruby 3.3 or later.

Work in a new, empty directory for the rest of this tutorial.

## 1. Create the Gemfile

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gem "fast-uuid"
```

Run `bundle install`.

If you're working against an unreleased checkout of fast-uuid instead of the published
gem, replace its line with `gem "fast-uuid", path: "/path/to/fast-uuid"`.

## 2. Generate UUIDs

Create `generate.rb`:

```ruby
# frozen_string_literal: true

require "fast/uuid"

v4 = Fast::UUID.v4
puts v4
puts v4.version

v7 = Fast::UUID.v7
puts v7
puts v7.timestamp
```

Run `bundle exec ruby generate.rb`. The v4 line is 122 random bits arranged into the
canonical shape, something like `e58ed033-6db7-4f1c-a4c1-6b73f0a91d54`; the v7 line
begins with the twelve hex digits of the current Unix time in milliseconds, so two
runs print different leading characters and different timestamps.

`Fast::UUID.generate` is v7, the RFC's recommended default. When all you want is "an
ID", that's the call:

```ruby
Fast::UUID.generate.version # => 7
```

Each constructor has a String twin — `Fast::UUID.uuid`, `uuid_v1`, `uuid_v3`,
`uuid_v4`, `uuid_v5`, `uuid_v6`, `uuid_v7` — which renders the canonical form and
skips the value object. The names are the stdlib's own, and `uuid_v4` and `uuid_v7`
are drop-ins for `SecureRandom.uuid_v4` and `SecureRandom.uuid_v7`:

```ruby
Fast::UUID.uuid_v4.class # => String, the canonical form, frozen
```

Both forms are frozen and immutable value objects — the String twins just skip the
object wrapper. Whatever you can do with the 36 characters you can do with the object,
and the rest of this tutorial is the part you can't.

## 3. Derive one from a name

Sometimes the identifier should not be invented but derived: the same input, the same
UUID, in every process, on every machine, at any time — no storage, no coordination.
v5 hashes a namespace and a name into the identifier (v3 is the same construction with
MD5; prefer v5 where possible):

```ruby
# frozen_string_literal: true

require "fast/uuid"

namespace = Fast::UUID::NAMESPACE_URL

uuid = Fast::UUID.v5(namespace, "https://example.com/docs/rfc9562")
puts uuid.version
puts uuid == Fast::UUID.v5(namespace, "https://example.com/docs/rfc9562")
```

Run it: `5`, then `true`. Nothing was random, so nothing needs remembering — the UUID
is a pure function of the namespace and the name. Use it when the name already
identifies the thing: a stable ID for a URL, a slug, an external key, a test fixture.
The namespaces are the RFC §6.6 well-known constants — `NAMESPACE_DNS`, `NAMESPACE_URL`,
`NAMESPACE_OID`, `NAMESPACE_X500` — or any UUID you fix once and never regenerate.

## 4. Parse one from the outside world

UUIDs arrive as Strings: a header, a form field, a row of a CSV. `Fast::UUID.parse`
turns one into the value object, and the RFC's grammar is the only rule it applies —
case doesn't matter, and neither does the version or variant:

```ruby
# frozen_string_literal: true

require "fast/uuid"

parsed = Fast::UUID.parse("C232AB00-9414-11EC-B3C8-9F6BDECED846")
puts parsed.version
puts parsed.to_s
```

Run it and you'll see `1` and `c232ab00-9414-11ec-b3c8-9f6bdeced846`: the RFC 9562
Appendix A v1 vector, parsed in upper case, rendered in the canonical lower case.

The input doesn't have to be a String, either. Anything string-like is accepted where
a String is expected — a Symbol parses as neatly as the String it prints as:

```ruby
Fast::UUID.parse(:"C232AB00-9414-11EC-B3C8-9F6BDECED846") == parsed # => true
```

A String the grammar rejects raises `Fast::UUID::ParseError`, and an object with no
`to_s` raises `TypeError`. Step 7 uses the non-raising form when the input is
untrusted; in your own code, reach for `parse` when a UUID is required and anything
else is a bug you want to hear about.

## 5. Read what it tells you

Every UUID reports its version — the nibble, whatever it is — and its variant:

```ruby
# frozen_string_literal: true

require "fast/uuid"

[
  Fast::UUID.parse("C232AB00-9414-11EC-B3C8-9F6BDECED846"), # v1
  Fast::UUID.parse("5df41881-3aed-3515-88a7-2f4a814cf09e"), # v3
  Fast::UUID.v4,
  Fast::UUID.v7
].each do |uuid|
  puts "#{uuid.version} #{uuid.variant}"
end
```

The output is `1 rfc9562`, `3 rfc9562`, `4 rfc9562` and `7 rfc9562`. The time-based
versions also report when they were made: `timestamp` returns a UTC `Time` for v1, v6
and v7 — v1 and v6 on the 100-ns Gregorian grid whose baseline is 1582-10-15, v7 on
the Unix clock to the millisecond — and nil for everything else.

```ruby
Fast::UUID.parse("5df41881-3aed-3515-88a7-2f4a814cf09e").timestamp # => nil (v3 carries no time)
Fast::UUID.v7(time: Time.utc(2024, 1, 15, 12, 0, 0)).timestamp     # => 2024-01-15 12:00:00 UTC
```

Generate now, parse years later, ask when — the time travels in the identifier.

## 6. Sort them

`Fast::UUID` includes `Comparable`, and `<=>` compares the raw 128 bits, which is what
the RFC means by opaque byte order. For v6 and v7 that order is chronological — the
timestamp sits in the leading bytes — so a sorted Array of v7 UUIDs is a timeline:

```ruby
# frozen_string_literal: true

require "fast/uuid"

start = Time.at(1_700_000_000)
ids = 3.times.map { |i| Fast::UUID.v7(time: start + i) }

sorted = ids.sort
puts sorted.first == ids.first
```

`true`: already in order, because the leading bytes are the timestamp. The extremes
sort where the bits put them: `Fast::UUID::NIL` before every other UUID,
`Fast::UUID::MAX` after.

One caveat the RFC does not decide for you, and the reason a how-to exists: v1 is also
time-based, but its `time_low` field sits first in the byte string, so v1 UUIDs do not
sort in time order. Byte order and time order agree for v6 and v7 only. See
[How to sort UUIDs](../how-to/sort-uuids.md).

## 7. Put it together: a sortable request ID

Everything so far composes into a small module your application can own. Create
`request_id.rb`:

```ruby
# frozen_string_literal: true

require "fast/uuid"

module RequestID
  def self.issue(at: Time.now)
    Fast::UUID.v7(time: at)
  end

  def self.named(url)
    Fast::UUID.v5(Fast::UUID::NAMESPACE_URL, url)
  end

  def self.accept(string)
    Fast::UUID.parse?(string) or raise ArgumentError, "not a UUID: #{string.inspect}"
  end

  def self.key(uuid)
    uuid.bytes
  end
end

issued = RequestID.issue(at: Time.at(1_700_000_000))
again  = RequestID.accept(issued.to_s)
stable = RequestID.named("https://example.com/docs/rfc9562")

puts again == issued
puts RequestID.key(issued).bytesize
puts stable.version
```

Run it: `true`, then `16`, then `5`. The ID is issued at a known millisecond
(`v7(time:)` — deterministic enough to assert on in tests), accepted back from its
wire form by a parser that raises on garbage, stored as the 16 raw bytes it is — the
form the RFC recommends for columns and keys — and derived from a name when nothing
should be stored at all. `new(bytes)` reads the key back out:

```ruby
Fast::UUID.new(RequestID.key(issued)) == issued # => true
```

## What you've built

An identifier you generate in one call or derive from a name, accept from untrusted
hands, read the time out of, sort without a comparison key, and store in 16 bytes.
From here:

- [How to choose a UUID version](../how-to/choose-a-uuid-version.md) turns the
  version question into a decision.
- [What a UUID is, and what its versions are](../explanation/uuid-versions.md) is the
  tour of what the versions are for.
- [How to generate deterministic UUIDs](../how-to/generate-deterministic-uuids.md)
  pins a UUID to an exact timestamp and keeps its tail stable.
- [How to validate untrusted input](../how-to/validate-untrusted-input.md) covers what
  `parse?` and `valid?` return and what `parse` raises.
- [Reference: Fast::UUID](../reference/uuid.md) lists the whole surface.
