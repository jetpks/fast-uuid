# Parsing and Validating UUIDs

This guide covers how to parse UUID strings and validate their format using fast-uuid.

## Parsing UUIDs

### Basic parsing

```ruby
uuid = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
uuid.version  # => 7
uuid.variant  # => :rfc9562
uuid.to_s     # => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
```

The parser accepts the canonical RFC 9562 format: 32 hexadecimal characters in the pattern `8-4-4-4-12` (with hyphens).

### Case insensitivity

```ruby
# Uppercase
uuid_upper = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")

# Lowercase
uuid_lower = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")

# Mixed case
uuid_mixed = Fast::UUID.parse("017f22E2-79B0-7cc3-98C4-dc0c0c07398F")

uuid_upper == uuid_lower == uuid_mixed  # => true
```

All parsed UUIDs are normalized to lowercase in their string representation.

### String-like inputs

The parser accepts anything that can be converted to a string:

```ruby
# Symbol
uuid = Fast::UUID.parse(:"017f22e2-79b0-7cc3-98c4-dc0c0c07398f")

# Object with #to_s
carrier = Object.new
def carrier.to_s
  "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
end
uuid = Fast::UUID.parse(carrier)

# Both produce the same result
Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f") == uuid  # => true
```

### Parse errors

Parsing raises `Fast::UUID::ParseError` for invalid input:

```ruby
begin
  Fast::UUID.parse("not-a-uuid")
rescue Fast::UUID::ParseError => e
  puts e.message  # => "not a valid UUID: not-a-uuid"
end
```

Invalid formats include:
- Empty strings
- Strings without hyphens
- Strings with wrong number of hex characters
- Strings with non-hex characters
- Braced UUIDs: `{017f22e2-79b0-7cc3-98c4-dc0c0c07398f}`
- URN form: `urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f`
- Strings with trailing whitespace

### Safe parsing with parse?

Use `parse?` when you want to handle invalid input gracefully:

```ruby
# Valid UUID
uuid = Fast::UUID.parse?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
if uuid
  puts "Valid: #{uuid}"
end
# => "Valid: 017f22e2-79b0-7cc3-98c4-dc0c0c07398f"

# Invalid UUID
uuid = Fast::UUID.parse?("not-a-uuid")
if uuid
  puts "Valid: #{uuid}"
else
  puts "Invalid UUID"
end
# => "Invalid UUID"
```

`parse?` returns `nil` for:
- Invalid UUID strings
- Objects with no string form (no `#to_s`)
- Objects whose `#to_s` returns an invalid UUID

### Type errors

Parsing raises `TypeError` for objects that have no string representation:

```ruby
blank = Class.new(BasicObject).new

begin
  Fast::UUID.parse(blank)
rescue TypeError => e
  puts e.message  # => "no implicit conversion into Fast::UUID"
end
```

## Validating UUIDs

### Basic validation

```ruby
Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")  # => true
Fast::UUID.valid?("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")  # => true
Fast::UUID.valid?("not-a-uuid")                            # => false
```

### Validation behavior

`valid?` checks **only** the string format against the RFC 9562 canonical grammar:
- Exactly 36 characters
- 32 hexadecimal digits (0-9, a-f, A-F)
- 4 hyphens at positions 8, 13, 18, 23
- No other characters

It does **not** validate:
- Version number (any value 0-15 is accepted)
- Variant (any variant bits are accepted)

```ruby
# Nil UUID (all zeros) - valid format
Fast::UUID.valid?("00000000-0000-0000-0000-000000000000")  # => true

# Max UUID (all ones) - valid format
Fast::UUID.valid?("ffffffff-ffff-ffff-ffff-ffffffffffff")  # => true

# Version 0 with NCS variant - valid format
Fast::UUID.valid?("ffffffff-ffff-0fff-0fff-ffffffffffff")  # => true

# Version 15 with Future variant - valid format
Fast::UUID.valid?("ffffffff-ffff-ffff-ffff-ffffffffffff")  # => true
```

### String-like inputs for validation

```ruby
# Symbol
Fast::UUID.valid?(:"017f22e2-79b0-7cc3-98c4-dc0c0c07398f")  # => true

# Object with #to_s
carrier = Object.new
def carrier.to_s
  "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
end
Fast::UUID.valid?(carrier)  # => true

# Invalid object
Fast::UUID.valid?(42)  # => false
Fast::UUID.valid?(nil)  # => false
```

### Type errors in validation

`valid?` returns `false` (not `TypeError`) for objects with no string form:

```ruby
blank = Class.new(BasicObject).new
Fast::UUID.valid?(blank)  # => false
```

## Common patterns

### Validate then parse

```ruby
input = "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"

if Fast::UUID.valid?(input)
  uuid = Fast::UUID.parse(input)
  # Work with uuid...
else
  # Handle invalid input
end
```

### Parse with fallback

```ruby
input = user_input
uuid = Fast::UUID.parse?(input) || Fast::UUID.v7
# If input is valid, use it; otherwise generate a new v7 UUID
```

### Batch validation

```ruby
inputs = ["uuid1", "uuid2", "invalid"]
valid_uuids = inputs.filter_map { |s| Fast::UUID.parse?(s) }
# => [#<Fast::UUID>, #<Fast::UUID>] (skips "invalid")
```

### Parse from various sources

```ruby
# From command line argument
uuid = Fast::UUID.parse(ARGV.first)

# From environment variable
uuid = Fast::UUID.parse(ENV["REQUEST_ID"])

# From HTTP header
uuid = Fast::UUID.parse(request.headers["X-Request-ID"])

# From database
uuid = Fast::UUID.parse(record.uuid_string)
```

## Parsing edge cases

### Nil and Max UUIDs

```ruby
# Nil UUID (all zeros)
nil_uuid = Fast::UUID.parse("00000000-0000-0000-0000-000000000000")
nil_uuid.nil_uuid?  # => true

# Max UUID (all ones)
max_uuid = Fast::UUID.parse("ffffffff-ffff-ffff-ffff-ffffffffffff")
max_uuid.max_uuid?  # => true
```

### Unknown versions

```ruby
# Version 2 (not generated by fast-uuid, but parseable)
uuid = Fast::UUID.parse("00000000-0000-2000-8000-000000000000")
uuid.version  # => 2

# Version 8 (reserved)
uuid = Fast::UUID.parse("00000000-0000-8000-8000-000000000000")
uuid.version  # => 8
```

### All variants

```ruby
# RFC 9562 variant (10xx) - most common
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
uuid.variant  # => :rfc9562

# NCS (Network Computing System) variant (0xxx)
uuid = Fast::UUID.parse("00000000-0000-0000-0000-000000000000")
uuid.variant  # => :ncs

# Microsoft variant (110x)
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-d8c4-dc0c0c07398f")
uuid.variant  # => :microsoft

# Future variant (111x)
uuid = Fast::UUID.parse("ffffffff-ffff-ffff-ffff-ffffffffffff")
uuid.variant  # => :future
```

## Performance considerations

Parsing is highly optimized:
- Valid UUID strings parse in ~6 object allocations
- Symbol inputs parse in ~6 allocations (no string copy needed)
- The parsed UUID object is frozen and immutable

For maximum performance in hot paths:
- Use `parse?` when invalid input is possible to avoid exception overhead
- Use Symbols for repeated parsing of the same UUID string
- Cache parsed UUIDs if you need to use them multiple times
