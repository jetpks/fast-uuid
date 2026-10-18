# Generate deterministic v3 and v5 UUIDs from names

## Steps

1. Pick a namespace. fast-uuid provides the four RFC namespaces as frozen UUID constants:

   ```ruby
   Fast::UUID::NAMESPACE_DNS.to_s  # => "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
   Fast::UUID::NAMESPACE_URL.to_s  # => "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
   Fast::UUID::NAMESPACE_OID.to_s  # => "6ba7b812-9dad-11d1-80b4-00c04fd430c8"
   Fast::UUID::NAMESPACE_X500.to_s # => "6ba7b814-9dad-11d1-80b4-00c04fd430c8"
   ```

   You can also use any UUID value object or any String that parses as a UUID.

2. Generate the UUID:

   ```ruby
   require "fast/uuid"

   uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
   uuid.to_s # => "2ed6657d-e927-568b-95e1-2665a8aea6a2"

   v3 = Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com")
   v3.to_s # => "5df41881-3aed-3515-88a7-2f4a814cf09e"

   # String twins — same digest, no value object:
   Fast::UUID.uuid_v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
   # => "2ed6657d-e927-568b-95e1-2665a8aea6a2"
   ```

The namespace may be given as the value object or as anything string-like that parses. A Symbol uses its `name`:

```ruby
Fast::UUID.v5(:"6ba7b810-9dad-11d1-80b4-00c04fd430c8", "www.example.com").to_s
# => "2ed6657d-e927-568b-95e1-2665a8aea6a2"
```

## Determinism

Same namespace + same name gives the same UUID every time:

```ruby
a = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
b = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
a == b # => true

# String form of the namespace is equivalent:
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS.to_s, "www.example.com") == a # => true
```

The name is its String form — Symbol or any `to_s` carrier. `42` and `"42"` produce the same UUID, `nil` and `""` produce the same UUID:

```ruby
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, 42) == Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "42") # => true
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, nil) == Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "") # => true
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, :"www.example.com") == Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com") # => true
```

Different names produce different UUIDs:

```ruby
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "example.com") == Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com") # => false
```

Inputs with no String form raise `TypeError`; a namespace whose String form does not parse raises `ParseError`:

```ruby
blank = Class.new(BasicObject).new
Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, blank) # raises TypeError
Fast::UUID.v3(blank, "www.example.com") # raises TypeError
Fast::UUID.v3("not-a-uuid", "www.example.com") # raises Fast::UUID::ParseError
```

## Known vectors

DNS namespace + `"www.example.com"` (RFC 9562 Appendix A.2 and A.4):

| Version | UUID |
|---|---|
| v3 | `5df41881-3aed-3515-88a7-2f4a814cf09e` |
| v5 | `2ed6657d-e927-568b-95e1-2665a8aea6a2` |

```ruby
require "fast/uuid"

Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com").to_s # => "5df41881-3aed-3515-88a7-2f4a814cf09e"
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com").to_s # => "2ed6657d-e927-568b-95e1-2665a8aea6a2"

Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com").version # => 3
Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com").version # => 5
```

## v5 or v3

Prefer v5: SHA-1 over the namespace bytes + name bytes, leftmost 128 bits of the 160-bit digest, version 5 and `10xx` variant stamped in place. v3 is MD5 over the same input, whole 128-bit digest, version 3 stamped.

```ruby
Fast::UUID.uuid_v3(Fast::UUID::NAMESPACE_DNS, "www.example.com")
# => "5df41881-3aed-3515-88a7-2f4a814cf09e"  # frozen String
Fast::UUID.uuid_v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
# => "2ed6657d-e927-568b-95e1-2665a8aea6a2"  # frozen String
```

`uuid_v3` and `uuid_v5` return the String directly, skipping the value object. See [Fast::UUID — API reference](../reference/fast-uuid.md) for signatures.
