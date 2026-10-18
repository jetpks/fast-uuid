# Getting started with fast-uuid

## Prerequisites

Ruby 3.3 or later. Install the gem and require it:

```sh
gem install fast-uuid
```

```ruby
require "fast/uuid"
```

The require path is `fast/uuid`. See [Fast::UUID — API reference](../reference/fast-uuid.md) for Ruby floor and dependency details.

## Generate your first UUID

`Fast::UUID.generate` returns a `Fast::UUID` with version 7, the RFC's recommended default:

```ruby
require "fast/uuid"

uuid = Fast::UUID.generate
uuid.to_s   # => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"  # canonical lowercase 8-4-4-4-12, 36 chars, frozen
uuid.class  # => Fast::UUID
```

`to_s` is the canonical lowercase dashed form, frozen at construction. For a purely random UUID, use `Fast::UUID.v4`:

```ruby
random = Fast::UUID.v4
random.version # => 4
```

`Fast::UUID.uuid` and `Fast::UUID.uuid_v7` are the String-returning twins — they render the same bits straight to a frozen canonical String without allocating a value object. See [Replace SecureRandom UUID generation with fast-uuid](../how-to-guides/replace-securerandom.md).

## Inspect it

Every UUID carries a version nibble and a variant tag:

```ruby
uuid = Fast::UUID.generate

uuid.version # => 7  # 0-15, the version nibble
uuid.variant # => :rfc9562  # :rfc9562, :microsoft, :future, or :ncs
```

`#timestamp` returns a UTC `Time` for time-based versions at the resolution that version encodes:

```ruby
v7 = Fast::UUID.v7(time: Time.utc(2022, 2, 22, 19, 22, 22))
v7.timestamp # => 2022-02-22 19:22:22 UTC  # millisecond resolution for v7
v7.timestamp.utc? # => true
```

Non-time versions have no timestamp:

```ruby
Fast::UUID.v4.timestamp          # => nil
Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com").timestamp # => nil
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com").timestamp # => nil
```

v4, v3, and v5 answer `nil` for `#timestamp`. Only v1, v6, and v7 return a `Time`.

## Parse one back

Parsing is case-insensitive against the RFC 9562 canonical grammar:

```ruby
uuid = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
uuid.to_s # => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"

uuid2 = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid == uuid2 # => true
```

Invalid strings raise `Fast::UUID::ParseError`:

```ruby
begin
  Fast::UUID.parse("not-a-uuid")
rescue Fast::UUID::ParseError => e
  e.message # => "not a valid UUID: not-a-uuid"
end
```

`parse?` answers `nil` instead of raising:

```ruby
Fast::UUID.parse?("not-a-uuid") # => nil
Fast::UUID.parse?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f") # => #<Fast::UUID ...>
```

See [Validate and parse UUID strings from user input](../how-to-guides/validate-user-input.md) for the full table of `parse` / `parse?` / `valid?` and the grammar.

## Compare and sort

`==` compares the 128-bit value only. Sorting works and v7 sorts chronologically:

```ruby
time = Time.utc(2022, 2, 22, 19, 22, 22)
ids = [
  Fast::UUID.v7(time: time + 2),
  Fast::UUID.v7(time: time),
  Fast::UUID.v7(time: time + 1)
]
ids.sort.map(&:timestamp) # => [time, time + 1, time + 2]
```

`Fast::UUID::NIL` and `Fast::UUID::MAX` bracket every UUID in opaque unsigned 128-bit byte order:

```ruby
Fast::UUID::NIL < Fast::UUID.v4  # => true
Fast::UUID.v4 < Fast::UUID::MAX  # => true
```

v1 does not sort chronologically — its `time_low` field sits first on the wire. See [How the versions and variants are laid out](../explanation/version-variant-layout.md).

## Where to go next

- [Choose a UUID version](../how-to-guides/choose-a-uuid-version.md) — decide which version fits a new column or use case.
- [Validate and parse UUID strings from user input](../how-to-guides/validate-user-input.md) — handle strings from users, forms, and requests.
- [Fast::UUID — API reference](../reference/fast-uuid.md) — the complete method, constant, and error listing.
