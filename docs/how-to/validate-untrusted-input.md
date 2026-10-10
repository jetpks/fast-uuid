# How to validate untrusted input

Accept a String from a header, a query parameter or a CSV row only when it is a UUID,
without letting a malformed one raise. You need `Fast::UUID.parse?` or
`Fast::UUID.valid?`.

## Steps

1. Use `parse?` when you want the value. It returns the UUID or nil, for every bad
   shape and every wrong type alike:

   ```ruby
   Fast::UUID.parse?("017F22E2-79B0-7CC3-98C4-DC0C0C07398F") # => a Fast::UUID, version 7
   Fast::UUID.parse?("not-a-uuid")                           # => nil
   Fast::UUID.parse?(nil)                                    # => nil
   ```

2. Use `valid?` when you only need the check, for example in a form or a route
   constraint:

   ```ruby
   Fast::UUID.valid?("017F22E2-79B0-7CC3-98C4-DC0C0C07398F") # => true
   Fast::UUID.valid?("017F22E2-79B0-7CC3-98C4-DC0C0C07398")  # => false, 31 hex chars
   Fast::UUID.valid?(42)                                     # => false, not a String
   ```

3. Reserve `parse` for input a UUID is required for. It raises `Fast::UUID::ParseError`
   for a non-conforming String and `TypeError` for an object with no `to_s`, so a bad value stops
   the request loudly instead of becoming a nil you handle somewhere else:

   ```ruby
   begin
     Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398")
   rescue Fast::UUID::ParseError
     puts "rejected"
   end
   ```

   `rejected`.

## Notes

Validity is the RFC 9562 §4 grammar and nothing more: 32 hex digits and four hyphens,
case-insensitive. A well-formed UUID of any version and any variant passes — version 0,
version 15, Nil, Max. The RFC defines no version or variant gate, and a checker that
added one would reject values the RFC itself specifies;
[Why validity is the grammar and nothing more](../explanation/validity.md) has the
details. If you additionally need "was this one of mine", check `version`:

```ruby
uuid = Fast::UUID.parse?(input)
uuid && uuid.version == 7 # => your v7 IDs, nil otherwise
```
