# Getting Started with fast-uuid

This tutorial walks you through the fundamentals of using the fast-uuid gem to generate, parse, and work with RFC 9562 UUIDs in Ruby.

## Prerequisites

- Ruby 3.3 or later
- The fast-uuid gem installed: `gem install fast-uuid`

## Step 1: Require the library

```ruby
require "fast/uuid"
```

All public functionality is available through the `Fast::UUID` class.

## Step 2: Generate your first UUID

The simplest way to generate a UUID is with the recommended default, version 7:

```ruby
uuid = Fast::UUID.v7
puts uuid.to_s
# => "018e312f-4b1e-7000-8000-000000000000"
```

This returns a `Fast::UUID` value object. The string representation is in the canonical RFC 9562 format: 32 lowercase hexadecimal characters separated by hyphens in the 8-4-4-4-12 pattern.

If you just need a string and don't want the object overhead, use the string constructor:

```ruby
string_uuid = Fast::UUID.uuid_v7
puts string_uuid
# => "018e312f-4b1e-7000-8000-000000000000"
```

## Step 3: Generate other UUID versions

fast-uuid supports all standard UUID versions:

### Random UUIDs (v4)

```ruby
# As a value object
uuid_v4 = Fast::UUID.v4

# As a string (drop-in replacement for SecureRandom.uuid_v4)
string_v4 = Fast::UUID.uuid_v4
```

### Time-based UUIDs (v1, v6)

```ruby
# v1: Traditional time-based with 100-ns Gregorian timestamp
uuid_v1 = Fast::UUID.v1

# v6: Reordered fields for chronological sorting
uuid_v6 = Fast::UUID.v6

# With explicit time
specific_time = Time.utc(2024, 1, 15, 10, 30, 0)
uuid_v1_at_time = Fast::UUID.v1(time: specific_time)
uuid_v6_at_time = Fast::UUID.v6(time: specific_time)
```

### Name-based UUIDs (v3, v5)

These generate deterministic UUIDs from a namespace and a name using cryptographic hashes.

```ruby
# Using built-in DNS namespace
namespace = Fast::UUID::NAMESPACE_DNS
uuid_v3 = Fast::UUID.v3(namespace, "example.com")
uuid_v5 = Fast::UUID.v5(namespace, "example.com")

# The same namespace and name always produce the same UUID
uuid_v5_again = Fast::UUID.v5(namespace, "example.com")
uuid_v5 == uuid_v5_again  # => true
```

Available namespaces:
- `Fast::UUID::NAMESPACE_DNS`
- `Fast::UUID::NAMESPACE_URL`
- `Fast::UUID::NAMESPACE_OID`
- `Fast::UUID::NAMESPACE_X500`

## Step 4: Parse UUID strings

```ruby
# Parse a canonical UUID string
parsed = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
puts parsed.version  # => 7
puts parsed.variant  # => :rfc9562

# Parsing is case-insensitive
parsed_upper = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
parsed_lower = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
parsed_upper == parsed_lower  # => true

# Parse accepts anything string-like (Symbols, objects with #to_s)
parsed_symbol = Fast::UUID.parse(:"017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
```

## Step 5: Validate UUID strings

```ruby
# Check if a string is a valid RFC 9562 UUID
Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")  # => true
Fast::UUID.valid?("not-a-uuid")                            # => false
Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f ") # => false (trailing space)

# Note: valid? only checks the string format, not the version or variant
# These are all valid according to RFC 9562 grammar:
Fast::UUID.valid?("00000000-0000-0000-0000-000000000000")  # Nil UUID
Fast::UUID.valid?("ffffffff-ffff-ffff-ffff-ffffffffffff")  # Max UUID
```

## Step 6: Safe parsing with parse?

When you're not sure if input is a valid UUID, use `parse?` which returns `nil` instead of raising:

```ruby
uuid = Fast::UUID.parse?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
if uuid
  puts "Valid UUID: #{uuid}"
else
  puts "Not a valid UUID"
end
```

## Step 7: Work with UUID properties

```ruby
uuid = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 10, 30, 0))

# Version and variant
uuid.version   # => 7
uuid.variant   # => :rfc9562

# Timestamp (for time-based versions)
uuid.timestamp # => 2024-01-15 10:30:00 UTC

# Raw bytes
uuid.bytes     # => 16-byte binary string (frozen)

# String representations
uuid.to_s      # => "018e312f-4b1e-7000-8000-000000000000" (canonical)
uuid.hex       # => "018e312f4b1e70008000000000000000" (32 hex chars, no hyphens)
uuid.urn       # => "urn:uuid:018e312f-4b1e-7000-8000-000000000000"
```

## Step 8: Compare UUIDs

UUIDs are comparable and can be sorted:

```ruby
uuid1 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 10, 0, 0))
uuid2 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 11, 0, 0))
uuid3 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 10, 30, 0))

uuid1 < uuid2    # => true
uuid1 <= uuid3   # => true
uuid2 > uuid1    # => true

# v6 and v7 sort chronologically as raw bytes
sorted = [uuid2, uuid1, uuid3].sort
# => [uuid1, uuid3, uuid2] (chronological order)
```

## Step 9: Special UUIDs

```ruby
# Nil UUID (all zeros)
Fast::UUID::NIL.nil_uuid?  # => true

# Max UUID (all ones)
Fast::UUID::MAX.max_uuid?  # => true

# Both are valid and comparable
Fast::UUID::NIL < Fast::UUID.v7 < Fast::UUID::MAX  # => true
```

## Step 10: Use as hash keys

UUIDs work well as hash keys:

```ruby
uuid = Fast::UUID.v7
hash = { uuid => "my value" }
hash[uuid]  # => "my value"

# Same UUID from different construction methods are equal
hash[Fast::UUID.parse(uuid.to_s)]  # => "my value"
```

## Complete example: Building a simple ID service

```ruby
require "fast/uuid"

class IdService
  NAMESPACE = Fast::UUID::NAMESPACE_URL

  def self.generate_id
    Fast::UUID.v7
  end

  def self.generate_id_for(url)
    Fast::UUID.v5(NAMESPACE, url)
  end

  def self.valid_id?(id)
    Fast::UUID.valid?(id)
  end

  def self.parse_id(id)
    Fast::UUID.parse(id)
  rescue Fast::UUID::ParseError
    nil
  end
end

# Usage
id = IdService.generate_id
puts "New ID: #{id}"

url_id = IdService.generate_id_for("https://example.com/users/1")
puts "URL ID: #{url_id}"

parsed = IdService.parse_id("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
puts "Parsed: #{parsed}"
```

## Next steps

- [Generate UUIDs](https://github.com/jetpks/fast-uuid/blob/main/docs/how-to-guides/generating-uuids.md) — Deep dive into all generation options
- [Parse and Validate UUIDs](https://github.com/jetpks/fast-uuid/blob/main/docs/how-to-guides/parsing-and-validating.md) — Advanced parsing scenarios
- [API Reference](https://github.com/jetpks/fast-uuid/blob/main/docs/reference/api.md) — Complete method documentation
