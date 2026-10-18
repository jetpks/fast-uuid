# Using Name-based UUIDs (v3 and v5)

This guide covers generating and working with name-based UUIDs (v3 and v5) using fast-uuid.

## Overview

Name-based UUIDs generate deterministic UUIDs from a namespace and a name using cryptographic hash functions:

- **v3**: Uses MD5 hash (128-bit digest)
- **v5**: Uses SHA-1 hash (160-bit digest, truncated to 128 bits)

The same namespace and name always produce the same UUID, making them useful for:
- Generating consistent identifiers for resources
- Creating UUIDs from URLs, domain names, or other unique strings
- Distributed systems where the same input must produce the same output

## Basic usage

### v3 (MD5-based)

```ruby
namespace = Fast::UUID::NAMESPACE_DNS
name = "www.example.com"

uuid = Fast::UUID.v3(namespace, name)
uuid.version  # => 3
uuid.variant  # => :rfc9562
uuid.to_s     # => "5df41881-3aed-3515-88a7-2f4a814cf09e"
```

### v5 (SHA-1-based)

```ruby
namespace = Fast::UUID::NAMESPACE_DNS
name = "www.example.com"

uuid = Fast::UUID.v5(namespace, name)
uuid.version  # => 5
uuid.variant  # => :rfc9562
uuid.to_s     # => "2ed6657d-e927-568b-95e1-2665a8aea6a2"
```

### String output

```ruby
# v3 as string
string_v3 = Fast::UUID.uuid_v3(namespace, name)
# => "5df41881-3aed-3515-88a7-2f4a814cf09e"

# v5 as string
string_v5 = Fast::UUID.uuid_v5(namespace, name)
# => "2ed6657d-e927-568b-95e1-2665a8aea6a2"
```

## Namespaces

### Built-in namespaces

fast-uuid provides the standard namespaces from RFC 9562 Appendix A:

```ruby
# DNS namespace (for domain names)
Fast::UUID::NAMESPACE_DNS
# => #<Fast::UUID:0x00007f8a0b0c0d0e @bytes="6ba7b810-9dad-11d1-80b4-00c04fd430c8">

# URL namespace (for URLs)
Fast::UUID::NAMESPACE_URL
# => #<Fast::UUID:0x00007f8a0b0c0d0e @bytes="6ba7b811-9dad-11d1-80b4-00c04fd430c8">

# OID namespace (for ISO OIDs)
Fast::UUID::NAMESPACE_OID
# => #<Fast::UUID:0x00007f8a0b0c0d0e @bytes="6ba7b812-9dad-11d1-80b4-00c04fd430c8">

# X.500 namespace (for X.500 DNs)
Fast::UUID::NAMESPACE_X500
# => #<Fast::UUID:0x00007f8a0b0c0d0e @bytes="6ba7b814-9dad-11d1-80b4-00c04fd430c8">
```

### Using built-in namespaces

```ruby
# DNS namespace for domain names
domain_uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "example.com")

# URL namespace for URLs
url_uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_URL, "https://example.com/page")

# OID namespace for OIDs
# (Note: OIDs are typically represented as strings like "1.2.3.4")
oid_uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_OID, "1.2.3.4")
```

### Custom namespaces

You can use any UUID as a namespace:

```ruby
# Use a previously generated UUID as namespace
custom_namespace = Fast::UUID.v4
uuid = Fast::UUID.v5(custom_namespace, "my-resource")

# Use a parsed UUID as namespace
custom_namespace = Fast::UUID.parse("12345678-1234-5678-1234-567812345678")
uuid = Fast::UUID.v3(custom_namespace, "my-resource")
```

### Namespace as string

Namespaces can be passed as strings and will be parsed automatically:

```ruby
# String representation of DNS namespace
uuid = Fast::UUID.v5("6ba7b811-9dad-11d1-80b4-00c04fd430c8", "example.com")

# Same as using Fast::UUID::NAMESPACE_URL
uuid == Fast::UUID.v5(Fast::UUID::NAMESPACE_URL, "example.com")  # => true
```

## Name formats

### String names

```ruby
uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "example.com")
```

### Symbol names

Symbols are accepted and their `#name` (a frozen String) is used:

```ruby
uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, :example_com)
# Equivalent to: Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "example_com")
```

### Object with #to_s

Any object that responds to `#to_s` can be used as a name:

```ruby
name_obj = Object.new
def name_obj.to_s
  "example.com"
end

uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, name_obj)
# Equivalent to: Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "example.com")
```

### Integer names

Integers are converted to strings via `#to_s`:

```ruby
uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, 42)
# Equivalent to: Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "42")
```

### nil names

`nil` is converted to an empty string:

```ruby
uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, nil)
# Equivalent to: Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "")
```

## Determinism

The same namespace and name always produce the same UUID:

```ruby
namespace = Fast::UUID::NAMESPACE_DNS
name = "www.example.com"

uuid1 = Fast::UUID.v5(namespace, name)
uuid2 = Fast::UUID.v5(namespace, name)

uuid1 == uuid2  # => true
```

This makes name-based UUIDs ideal for:
- Caching keys
- Distributed ID generation
- Resource identification where the same input must map to the same output

## RFC 9562 Test Vectors

The gem correctly generates the RFC 9562 test vectors for name-based UUIDs:

```ruby
# v3 test vector: DNS namespace + "www.example.com"
uuid = Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com")
uuid.to_s  # => "5df41881-3aed-3515-88a7-2f4a814cf09e"

# v5 test vector: DNS namespace + "www.example.com"
uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
uuid.to_s  # => "2ed6657d-e927-568b-95e1-2665a8aea6a2"
```

## Practical use cases

### Generating IDs for URLs

```ruby
namespace = Fast::UUID::NAMESPACE_URL

urls = [
  "https://example.com/page1",
  "https://example.com/page2",
  "https://example.com/page1"  # Duplicate
]

url_ids = urls.map { |url| Fast::UUID.v5(namespace, url) }
# => [#<Fast::UUID>, #<Fast::UUID>, #<Fast::UUID>]

# Same URL produces same UUID
url_ids[0] == url_ids[2]  # => true
```

### Generating IDs for database records

```ruby
namespace = Fast::UUID::NAMESPACE_DNS

class User
  UUID_NAMESPACE = Fast::UUID::NAMESPACE_DNS

  def self.uuid_for(email)
    Fast::UUID.v5(UUID_NAMESPACE, email.downcase)
  end
end

# Same email always produces same UUID
user1_uuid = User.uuid_for("user@example.com")
user2_uuid = User.uuid_for("user@example.com")
user1_uuid == user2_uuid  # => true
```

### Generating IDs for file paths

```ruby
namespace = Fast::UUID::NAMESPACE_URL

class Document
  def self.uuid_for(path)
    # Use absolute path as name
    absolute_path = File.expand_path(path)
    Fast::UUID.v5(namespace, absolute_path)
  end
end

# Same file path always produces same UUID
doc1_uuid = Document.uuid_for("/path/to/file.txt")
doc2_uuid = Document.uuid_for("/path/to/file.txt")
doc1_uuid == doc2_uuid  # => true
```

### Generating IDs for composite keys

```ruby
namespace = Fast::UUID::NAMESPACE_DNS

# Combine multiple values into a single name
def uuid_for_user_and_resource(user_id, resource_id)
  name = "#{user_id}:#{resource_id}"
  Fast::UUID.v5(namespace, name)
end

# Same combination always produces same UUID
uuid1 = uuid_for_user_and_resource("user1", "resource1")
uuid2 = uuid_for_user_and_resource("user1", "resource1")
uuid1 == uuid2  # => true
```

## v3 vs v5: Which to choose?

| Aspect | v3 (MD5) | v5 (SHA-1) |
|--------|----------|------------|
| Hash function | MD5 | SHA-1 |
| Digest size | 128 bits | 160 bits (truncated to 128) |
| Collision resistance | Lower | Higher |
| Security | Cryptographically broken | More secure |
| Performance | Slightly faster | Slightly slower |
| RFC 9562 | Yes | Yes |

**Recommendation**: Use v5 (SHA-1) for new applications. MD5 is considered cryptographically broken, though it may still be acceptable for non-security-critical use cases where collision resistance is not a concern.

## Performance

Name-based UUID generation has higher allocation costs due to hash computation:
- v3: ~8 object allocations
- v5: ~9 object allocations

With Symbol names (which don't need `#to_s` copy):
- v3: ~7 object allocations
- v5: ~8 object allocations

## Error handling

### Invalid namespace

```ruby
begin
  Fast::UUID.v5("not-a-uuid", "example.com")
rescue Fast::UUID::ParseError => e
  puts e.message  # => "not a valid UUID: not-a-uuid"
end
```

### Invalid name (no string form)

```ruby
no_string = Class.new(BasicObject).new

begin
  Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, no_string)
rescue TypeError => e
  puts e.message  # => "no implicit conversion into Fast::UUID"
end
```

### Safe generation

```ruby
def safe_v5(namespace, name)
  Fast::UUID.v5(namespace, name)
rescue Fast::UUID::ParseError, TypeError
  nil
end

uuid = safe_v5(Fast::UUID::NAMESPACE_DNS, "example.com")
# => #<Fast::UUID>

uuid = safe_v5("not-a-uuid", "example.com")
# => nil
```

## Tips

1. **Use v5 for new applications** - SHA-1 is more secure than MD5
2. **Use appropriate namespaces** - DNS for domain names, URL for URLs
3. **Normalize names** - Convert to lowercase, strip whitespace for consistency
4. **Cache results** - If generating the same UUID repeatedly, cache it
5. **Consider collision probability** - Even with hash functions, collisions are possible (though extremely unlikely)

## Example: URL shortener with name-based UUIDs

```ruby
class UrlShortener
  NAMESPACE = Fast::UUID::NAMESPACE_URL

  def self.shorten(url)
    # Normalize URL (remove protocol, trailing slash, etc.)
    normalized = normalize_url(url)
    # Generate deterministic UUID
    uuid = Fast::UUID.v5(NAMESPACE, normalized)
    # Return first 8 characters as short code
    uuid.hex[0..7]
  end

  def self.normalize_url(url)
    uri = URI.parse(url)
    "#{uri.host}#{uri.path}".downcase
  rescue URI::InvalidURIError
    url.downcase
  end
end

# Usage
code1 = UrlShortener.shorten("https://example.com/page")
code2 = UrlShortener.shorten("http://example.com/page/")
code1 == code2  # => true (same normalized URL)
```
