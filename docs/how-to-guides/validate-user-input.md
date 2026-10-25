# Validate and parse UUID strings from user input

## Raise, answer or boolean

| Method | Signature | Behavior |
|---|---|---|
| `Fast::UUID.parse(str)` | `parse(str) -> Fast::UUID` | Returns the UUID on a conforming String. Raises `Fast::UUID::ParseError` with `not a valid UUID: #{str}` on a non-conforming String. |
| `Fast::UUID.parse?(str)` | `parse?(str) -> Fast::UUID or nil` | Returns the UUID or `nil`. Swallows `TypeError` and `ParseError`. |
| `Fast::UUID.valid?(str)` | `valid?(str) -> true or false` | Answers `true`/`false`. Returns `false` on inputs with no `to_s` instead of raising. |

Use `valid?` or `parse?` at trust boundaries. Use `parse` where failure is a bug.

```ruby
require "fast/uuid"

Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f") # => #<Fast::UUID ...>
Fast::UUID.parse("nope") # raises Fast::UUID::ParseError: not a valid UUID: nope

Fast::UUID.parse?("nope") # => nil
Fast::UUID.parse?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f") # => #<Fast::UUID ...>

Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f") # => true
Fast::UUID.valid?("nope") # => false
```

## What counts as valid

The RFC 9562 Section 4 grammar only. Validity is the grammar and nothing more — the RFC defines no version or variant gate, and Nil and Max sit outside the `10xx` variant by design.

The grammar is case-insensitive. Any version (0–15) and any variant parses, Nil and Max included:

```ruby
Fast::UUID.valid?("00000000-0000-0000-0000-000000000000") # => true  # Nil
Fast::UUID.valid?("ffffffff-ffff-ffff-ffff-ffffffffffff") # => true  # Max
Fast::UUID.valid?("ffffffff-ffff-0fff-0fff-ffffffffffff") # => true  # v0, NCS
Fast::UUID.valid?("ffffffff-ffff-ffff-cfff-ffffffffffff") # => true  # v15, Microsoft
Fast::UUID.valid?("017F22E2-79B0-7CC3-98C4-DC0C0C07398F") # => true  # uppercase
```

For the exact regular expression, see [`CANONICAL` in the reference](../reference/fast-uuid.md#constants).

## What gets rejected

The following shapes raise `ParseError` from `parse` and answer `false` from `valid?`:

- empty string
- fragment (`017f22e2`)
- hyphenless
- one hex short (`017f22e2-79b0-7cc3-98c4-dc0c0c07398`, 35 chars)
- one hex long (`017f22e2-79b0-7cc3-98c4-dc0c0c07398ff`, 37 chars)
- shifted hyphens (`017f22e2-79b07cc3-98c4-dc0c0c07398f`)
- trailing hyphen (`017f22e2-79b0-7cc3-98c4-dc0c0c07398f-`)
- leading hyphen (`-017f22e2-79b0-7cc3-98c4-dc0c0c07398f`)
- non-hex first or last character (`g17f22e2-...`, `...07398g`)
- braced (`{017f22e2-79b0-7cc3-98c4-dc0c0c07398f}`)
- URN form (`urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f`)
- trailing whitespace or newline (`017f22e2-79b0-7cc3-98c4-dc0c0c07398f\n`)

URN is `#urn`'s job, not the parser's:

```ruby
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid.urn # => "urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
Fast::UUID.valid?("urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f") # => false
```

## String-like inputs

Symbols and any object with `#to_s` are accepted. Symbols use `#name`, avoiding a copy:

```ruby
Fast::UUID.parse(:"017f22e2-79b0-7cc3-98c4-dc0c0c07398f").to_s # => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"

carrier = Object.new
def carrier.to_s; "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"; end
Fast::UUID.parse(carrier).to_s # => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
Fast::UUID.valid?(carrier) # => true
```

`nil`, `42`, and Arrays convert via `to_s` then fail the grammar:

```ruby
Fast::UUID.parse(nil)  # raises Fast::UUID::ParseError: not a valid UUID:
Fast::UUID.parse(42)   # raises Fast::UUID::ParseError: not a valid UUID: 42
Fast::UUID.valid?(nil) # => false
Fast::UUID.valid?(42)  # => false
```

A `BasicObject` descendant has no `to_s` at all:

```ruby
blank = Class.new(BasicObject).new
Fast::UUID.parse(blank)  # raises TypeError: no implicit conversion into Fast::UUID
Fast::UUID.valid?(blank) # => false
Fast::UUID.parse?(blank)  # => nil
```
