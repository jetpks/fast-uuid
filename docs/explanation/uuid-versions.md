# What a UUID is, and what its versions are

A UUID is 128 bits, and the RFC assigns meaning to a few of them before you start: a
version nibble naming the recipe that filled the rest, a variant naming which RFC
answers for it, and — for some versions — time. The rest are yours. A UUID is not a
value derived from content you already have; it is an identifier you *construct*, with
properties you choose — the moment of its creation can travel inside it, its byte
order can be a timeline, the same name can give the same UUID forever.

This page is the tour of those properties. If you already know the property you need,
the how-to [How to choose a UUID version](../how-to/choose-a-uuid-version.md) skips it.

## The structure is assigned, not incidental

Four bits of byte 6 are the **version**, a nibble from 0 to 15; the top two bits of
byte 8 are the **variant**. Both travel with every UUID, and `#version` and `#variant`
report them whatever they find:

```ruby
Fast::UUID.v7.version # => 7
Fast::UUID.v7.variant # => :rfc9562
```

The versions fast-uuid generates are five of the nibbles: **v1** and **v6** time-based
on the Gregorian clock, **v3** and **v5** derived from a namespace and a name, **v4**
random, and **v7** time-based on the Unix clock with a random tail. The remaining
nibbles parse too — version and variant are data to report, never a gate
([Why validity is the grammar and nothing more](validity.md) is that page). The rest of
this page is what each assigned structure buys you.

## Embedded time

The time-based versions carry the moment of their creation inside the identifier. v1
and v6 encode a 60-bit count of 100-ns ticks on the Gregorian calendar — a clock whose
baseline is 1582-10-15, which is why the constant is called what it is. v7 encodes
48 bits of `unix_ts_ms`: Unix milliseconds, with sub-millisecond input truncated.
`#timestamp` reads the field back as a UTC `Time`:

```ruby
Fast::UUID.v7(time: Time.utc(2024, 1, 15, 12, 0, 0)).timestamp
# => 2024-01-15 12:00:00 UTC
Fast::UUID.v4.timestamp # => nil, randomness carries no time
```

The time is in the identifier itself: generate, store, parse years later by a process
that has never seen the generating clock, and ask when. v1 and v6 answer to
100 ns, v7 to the millisecond.

## Natural sorting

Because v6 and v7 put their timestamp in the leading bytes, sorting the identifiers as
opaque bytes — all `#<=>` ever does — sorts them by creation time (RFC 9562 §6.11):

```ruby
base = Time.utc(2024, 1, 15, 12, 0, 0)
ids = 3.times.map { |i| Fast::UUID.v7(time: base + i) }
ids.sort == ids # => true, the leading bytes are the timeline
```

§6.13 draws the practical consequence: store v7 keys as 128-bit binary and the index
keeps them chronologically clustered by construction — no timestamp column, no
secondary sort (see [How to store a UUID as 16 bytes](../how-to/store-a-uuid-as-16-bytes.md)).
v1 is the counter-example that proves the design matters: it carries the same kind of
timestamp but splits it least-significant-first, so its byte order breaks time order at
every `time_low` wrap.
[In what order UUIDs sort](comparison-order.md) has the layouts and the arithmetic.

## Name-derived determinism

v3 and v5 fill the 128 bits by hashing a namespace and a name: v5 with SHA-1 (its
leftmost 128 bits, the rightmost 32 discarded), v3 with MD5 — which is why the RFC says
prefer v5 where possible, MD5's collisions being practical. The namespace is one of the
RFC §6.6 well-known constants, or any UUID you fix once and never regenerate; the name
is any String, hashed as its bytes stand.

Same namespace, same name, same UUID — across processes, machines and years:

```ruby
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com").to_s
# => "2ed6657d-e927-568b-95e1-2665a8aea6a2", on every machine, forever
```

Nothing is random, so nothing needs remembering: no storage, no coordination, no
registry. The derived ID is a pure function of its input, which is reproducible
identity in production and a fixture you can assert on in tests
([How to generate deterministic UUIDs](../how-to/generate-deterministic-uuids.md)
works this vein).

## Pure randomness, when that is the ask

v4 draws 122 bits from the CSPRNG; the version nibble and the variant are the only
structure stamped in. No time, no name, no order — nothing but uniqueness itself, and
it is one option among five rather than the definition. When all you need is
uniqueness, v4 is exactly right, and nothing else about it pretends otherwise; when you
need time order or determinism too, the other versions buy them in the same 128 bits.

## Sentinels, and room for the future

Two UUIDs the RFC fixes as bounds: **Nil** (all zero bits) and **Max** (all one bits).
Both parse, both report — Nil is version 0 with the `:ncs` variant, Max is version 15
with `:future` — and both sort at the ends of any collection, as all zeros and all ones
must.

And the format leaves room in front of us: every version nibble 0–15 and all four
variants parse and introspect. A UUID minted by a version that did not exist when this
was written reports its number and stays opaque:

```ruby
Fast::UUID.parse("FFFFFFFF-FFFF-9FFF-FFFF-FFFFFFFFFFFF").version # => 9, reported, not rejected
```

That is the difference between structure and a checksum one more time: the fields are
there to be read, not to pass a test.

## Choosing

Each version is the same 128 bits with a different promise: v7 time and order, v5
determinism, v4 nothing but uniqueness, v6 and v1 a boundary with the Gregorian past.
[How to choose a UUID version](../how-to/choose-a-uuid-version.md) turns that into a
decision, the [reference](../reference/uuid.md) tabulates the calls, and
[the tutorial](../tutorials/generate-parse-and-sort-uuids.md) walks them in one pass.
