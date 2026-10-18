# Replace SecureRandom UUID generation with fast-uuid

## When to do this

Use fast-uuid when you want a canonical String and do not need a value object. `Fast::UUID.uuid_v4` and `Fast::UUID.uuid_v7` render straight to the frozen canonical form, skipping the `Fast::UUID` object. `Fast::UUID.uuid` is the default String form (v7).

All three use the same CSPRNG source as `SecureRandom`: `SecureRandom.bytes(16)`.

## Steps

1. Add the gem and require it:

   ```ruby
   gem "fast-uuid"
   ```

   ```ruby
   require "fast/uuid"
   ```

2. Replace call sites:

   ```ruby
   # before
   require "securerandom"
   SecureRandom.uuid_v4
   SecureRandom.uuid_v7

   # after
   require "fast/uuid"
   Fast::UUID.uuid_v4
   Fast::UUID.uuid_v7
   Fast::UUID.uuid        # default String form (v7)
   ```

   `uuid_v7(time:)` mirrors `v7(time:)` and accepts the same `time:` keyword:

   ```ruby
   time = Time.utc(2022, 2, 22, 19, 22, 22)
   Fast::UUID.uuid_v7(time: time) # frozen String with that timestamp
   Fast::UUID.v7(time: time)      # value object with the same timestamp
   ```

3. Keep `SecureRandom` for non-UUID randomness. fast-uuid replaces UUID generation only.

## Check the result

Strings are frozen, 36 characters, lowercase, and hyphenated as `8-4-4-4-12`:

```ruby
require "fast/uuid"

s = Fast::UUID.uuid_v4
s.frozen?  # => true
s.length   # => 36
s          # => "919108f7-52d1-4320-9bac-f847db4148a8" (example)
s.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/) # => true

v4 = Fast::UUID.uuid_v4
Fast::UUID.parse(v4).to_s == v4 # => true

v7 = Fast::UUID.uuid_v7
Fast::UUID.parse(v7).to_s == v7 # => true
```

Every String round-trips through `Fast::UUID.parse`:

```ruby
Fast::UUID.parse(s).to_s == s # => true for any single value s
```

## If you want the value object instead

Use `v4`, `v7`, and `generate` and call `to_s` when you need the String:

```ruby
require "fast/uuid"

uuid = Fast::UUID.v4
uuid.to_s # => "919108f7-52d1-4320-9bac-f847db4148a8" (example, frozen)

v7 = Fast::UUID.generate # v7 with no arguments
v7.to_s
```

See [Getting started with fast-uuid](../tutorials/getting-started.md) and [Fast::UUID — API reference](../reference/fast-uuid.md).
