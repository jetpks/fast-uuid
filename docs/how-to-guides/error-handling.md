# Error Handling

This guide covers the error types raised by fast-uuid and how to handle them.

## Error hierarchy

All errors raised by fast-uuid inherit from a common base:

```
Fast::UUID::Error
  ├── Fast::UUID::ParseError
```

### Fast::UUID::Error

Base error class for all fast-uuid errors. Inherits from `StandardError`.

### Fast::UUID::ParseError

Raised when a string cannot be parsed as a valid RFC 9562 UUID.

## ParseError scenarios

### Invalid UUID format

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
- Strings with wrong number of characters
- Strings with non-hexadecimal characters
- Braced UUIDs
- URN form UUIDs
- Strings with trailing whitespace

### Valid format, invalid UUID

```ruby
# These all raise ParseError
Fast::UUID.parse("")
Fast::UUID.parse("017f22e2")
Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398")  # too short
Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398ff")  # too long
Fast::UUID.parse("g17f22e2-79b0-7cc3-98c4-dc0c0c07398f")  # non-hex
Fast::UUID.parse("{017f22e2-79b0-7cc3-98c4-dc0c0c07398f}")  # braced
Fast::UUID.parse("urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f")  # URN
```

## TypeError scenarios

`TypeError` is raised (not a custom error) when an object cannot be converted to a string or doesn't have the expected type.

### Objects with no string form

```ruby
blank = Class.new(BasicObject).new

begin
  Fast::UUID.parse(blank)
rescue TypeError => e
  puts e.message  # => "no implicit conversion into Fast::UUID"
end
```

### Invalid node for v1/v6

```ruby
# Node must be Integer-like, String (6 bytes), Symbol, or nil
begin
  Fast::UUID.v1(node: "short")  # String must be exactly 6 bytes
rescue TypeError => e
  puts e.message  # => "a 6-byte node String is required (got 5 bytes)"
end

begin
  Fast::UUID.v1(node: [0x9f, 0x6b, 0xde, 0xce, 0xd8, 0x46])  # Array, not String
rescue TypeError => e
  puts e.message  # => "an Integer-like or 6-byte string-like node is required (got Array)"
end
```

### Invalid clock_sequence for v1/v6

```ruby
# Clock sequence must be Integer-like or nil
begin
  Fast::UUID.v1(clock_sequence: "0x33C8")  # String, not Integer
rescue TypeError => e
  puts e.message  # => "an Integer-like clock_sequence is required (got String)"
end

begin
  Fast::UUID.v1(clock_sequence: [0x33, 0xC8])  # Array
rescue TypeError => e
  puts e.message  # => "an Integer-like clock_sequence is required (got Array)"
end
```

### Invalid namespace for v3/v5

```ruby
# Namespace must be parseable as a UUID
begin
  Fast::UUID.v3("not-a-uuid", "example.com")
rescue Fast::UUID::ParseError => e
  puts e.message  # => "not a valid UUID: not-a-uuid"
end

begin
  Fast::UUID.v3(42, "example.com")
rescue Fast::UUID::ParseError => e
  puts e.message  # => "not a valid UUID: 42"
end
```

### Invalid name for v3/v5

```ruby
# Name must have a string form
no_string = Class.new(BasicObject).new

begin
  Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, no_string)
rescue TypeError => e
  puts e.message  # => "no implicit conversion into Fast::UUID"
end
```

### Invalid input to UUID.new

```ruby
# Must be a 16-byte binary String or object with #to_str returning one
begin
  Fast::UUID.new("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")  # 36 bytes, not 16
rescue ArgumentError => e
  puts e.message  # => "a 16-byte binary String is required (got 36 bytes)"
end

begin
  Fast::UUID.new(42)
rescue ArgumentError => e
  puts e.message  # => "a 16-byte binary String is required (got Integer)"
end
```

## Safe alternatives

### parse? for safe parsing

```ruby
# Returns nil instead of raising
uuid = Fast::UUID.parse?("not-a-uuid")
if uuid
  # Valid UUID
else
  # Invalid UUID - handle gracefully
end
```

### valid? for pre-validation

```ruby
# Check before parsing
if Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
  uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
else
  # Handle invalid input
end
```

## Error handling patterns

### Rescue specific errors

```ruby
def parse_uuid(input)
  Fast::UUID.parse(input)
rescue Fast::UUID::ParseError => e
  # Handle parse errors specifically
  log_error("Invalid UUID format: #{e.message}")
  nil
rescue TypeError => e
  # Handle type errors (no string form)
  log_error("Invalid input type: #{e.message}")
  nil
end
```

### Rescue all fast-uuid errors

```ruby
def parse_uuid(input)
  Fast::UUID.parse(input)
rescue Fast::UUID::Error => e
  # Handle any fast-uuid error
  log_error("UUID error: #{e.message}")
  nil
end
```

### Rescue with fallback

```ruby
def get_uuid(input, fallback: true)
  Fast::UUID.parse(input)
rescue Fast::UUID::ParseError, TypeError
  fallback ? Fast::UUID.v7 : nil
end

uuid = get_uuid(user_input)  # Returns parsed UUID or new v7
```

### Batch processing with error collection

```ruby
def parse_uuids(inputs)
  results = { valid: [], invalid: [] }
  inputs.each do |input|
    uuid = Fast::UUID.parse?(input)
    if uuid
      results[:valid] << uuid
    else
      results[:invalid] << input
    end
  end
  results
end

results = parse_uuids(["valid-uuid", "invalid", "another-valid"])
# => { valid: [#<Fast::UUID>, #<Fast::UUID>], invalid: ["invalid"] }
```

## Common error messages

| Scenario | Error Type | Message |
|----------|------------|---------|
| Invalid UUID string | `ParseError` | `"not a valid UUID: <input>"` |
| Object with no `#to_s` | `TypeError` | `"no implicit conversion into Fast::UUID"` |
| Node string not 6 bytes | `TypeError` | `"a 6-byte node String is required (got N bytes)"` |
| Node not Integer/String/Symbol/nil | `TypeError` | `"an Integer-like or 6-byte string-like node is required (got <class>)"` |
| Clock sequence not Integer/nil | `TypeError` | `"an Integer-like clock_sequence is required (got <class>)"` |
| Namespace not parseable | `ParseError` | `"not a valid UUID: <input>"` |
| Name with no string form | `TypeError` | `"no implicit conversion into Fast::UUID"` |
| UUID.new input not 16-byte String | `ArgumentError` | `"a 16-byte binary String is required (got N bytes)"` or `"a 16-byte binary String is required (got <class>)"` |

## Best practices

1. **Use `parse?` for user input** - Avoid exception overhead when invalid input is expected
2. **Use `valid?` for pre-checking** - When you want to validate before parsing
3. **Rescue specific errors** - Handle `ParseError` and `TypeError` separately if needed
4. **Provide fallbacks** - Generate a new UUID when parsing fails
5. **Log errors** - Include the invalid input in error messages for debugging
6. **Don't rescue Exception** - Only rescue the specific errors you expect

## Example: Robust UUID parser

```ruby
class UuidParser
  def initialize(fallback: false)
    @fallback = fallback
  end

  def parse(input)
    return nil if input.nil? || input.to_s.strip.empty?
    
    uuid = Fast::UUID.parse?(input)
    return uuid if uuid
    
    if @fallback
      warn("Invalid UUID '#{input}', generating new v7") if $VERBOSE
      return Fast::UUID.v7
    end
    
    raise Fast::UUID::ParseError, "not a valid UUID: #{input}"
  end

  def parse_batch(inputs)
    inputs.map { |input| parse(input) }
  end
end

# Usage
parser = UuidParser.new(fallback: true)

# Single value
uuid = parser.parse(user_input)

# Batch
uuids = parser.parse_batch(user_inputs)
```
