# Working with Timestamps

This guide covers how to extract and use timestamps from time-based UUIDs (v1, v6, v7).

## Which versions have timestamps?

Only time-based UUID versions store timestamps:

| Version | Timestamp | Precision | Sortable? |
|---------|-----------|----------|-----------|
| v1 | Gregorian (100-ns ticks) | 100 nanoseconds | No |
| v6 | Gregorian (100-ns ticks) | 100 nanoseconds | Yes |
| v7 | Unix Epoch (milliseconds) | 1 millisecond | Yes |
| v3, v4, v5 | None | N/A | N/A |

## Extracting timestamps

### v7 timestamps (Unix Epoch)

```ruby
time = Time.utc(2024, 1, 15, 10, 30, 0)
uuid = Fast::UUID.v7(time: time)

uuid.timestamp  # => 2024-01-15 10:30:00 UTC
```

v7 timestamps are stored as Unix Epoch milliseconds (48 bits), providing millisecond precision:

```ruby
# Millisecond precision
time = Time.utc(2024, 1, 15, 10, 30, 0, 123_456)  # 123456 microseconds
uuid = Fast::UUID.v7(time: time)
uuid.timestamp  # => 2024-01-15 10:30:00.123 UTC (truncated to milliseconds)

# Sub-millisecond values are truncated, not rounded
time = Time.utc(2024, 1, 15, 10, 30, 0, 999)  # 999 microseconds
uuid = Fast::UUID.v7(time: time)
uuid.timestamp  # => 2024-01-15 10:30:00.000 UTC (truncated)
```

### v1 and v6 timestamps (Gregorian)

v1 and v6 use a 60-bit Gregorian timestamp counting 100-nanosecond ticks since 1582-10-15 (the Gregorian epoch):

```ruby
time = Time.utc(2024, 1, 15, 10, 30, 0, 123_456_700)  # nanosecond precision
uuid_v1 = Fast::UUID.v1(time: time)
uuid_v6 = Fast::UUID.v6(time: time)

uuid_v1.timestamp  # => 2024-01-15 10:30:00.123456700 UTC
uuid_v6.timestamp  # => 2024-01-15 10:30:00.123456700 UTC
```

Both v1 and v6 store the same timestamp with 100-nanosecond precision, but v6 reorders the fields for chronological sorting.

### Non-time versions return nil

```ruby
uuid_v4 = Fast::UUID.v4
uuid_v4.timestamp  # => nil

uuid_v3 = Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "example.com")
uuid_v3.timestamp  # => nil

uuid_v5 = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "example.com")
uuid_v5.timestamp  # => nil
```

## RFC 9562 Test Vectors

The gem correctly parses timestamps from all RFC 9562 test vectors:

```ruby
# v1 test vector
uuid = Fast::UUID.parse("C232AB00-9414-11EC-B3C8-9F6BDECED846")
uuid.timestamp  # => 2022-02-22 19:22:22 UTC

# v6 test vector (same timestamp, reordered fields)
uuid = Fast::UUID.parse("1EC9414C-232A-6B00-B3C8-9F6BDECED846")
uuid.timestamp  # => 2022-02-22 19:22:22 UTC

# v7 test vector
uuid = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
uuid.timestamp  # => 2022-02-22 19:22:22 UTC
```

## Chronological sorting

### v7 sorting

v7 UUIDs sort chronologically as raw bytes because the timestamp is stored in the most significant bytes:

```ruby
t1 = Time.utc(2024, 1, 15, 10, 0, 0)
t2 = Time.utc(2024, 1, 15, 11, 0, 0)
t3 = Time.utc(2024, 1, 15, 10, 30, 0)

uuids = [
  Fast::UUID.v7(time: t2),
  Fast::UUID.v7(time: t1),
  Fast::UUID.v7(time: t3)
]

sorted = uuids.sort
# => [v7(t1), v7(t3), v7(t2)] - chronological order

sorted.map(&:timestamp) == [t1, t3, t2]  # => true
```

### v6 sorting

v6 UUIDs also sort chronologically:

```ruby
uuids = [
  Fast::UUID.v6(time: t2),
  Fast::UUID.v6(time: t1),
  Fast::UUID.v6(time: t3)
]

sorted = uuids.sort
# => [v6(t1), v6(t3), v6(t2)] - chronological order
```

### v1 does NOT sort chronologically

v1 UUIDs do **not** sort chronologically because the timestamp fields are stored least-significant-first:

```ruby
uuids = [
  Fast::UUID.v1(time: t2),
  Fast::UUID.v1(time: t1),
  Fast::UUID.v1(time: t3)
]

sorted = uuids.sort
# => NOT in chronological order
```

Use v6 or v7 if you need chronological sorting.

## Practical timestamp usage

### Age calculation

```ruby
uuid = Fast::UUID.v7
timestamp = uuid.timestamp
age_seconds = Time.now.utc - timestamp
age_hours = age_seconds / 3600
```

### Filter by time range

```ruby
start_time = Time.utc(2024, 1, 1)
end_time = Time.utc(2024, 1, 31)

uuids = [
  Fast::UUID.v7(time: Time.utc(2024, 1, 15)),
  Fast::UUID.v7(time: Time.utc(2024, 2, 1)),
  Fast::UUID.v7(time: Time.utc(2024, 1, 20))
]

# Filter to January 2024
january_uuids = uuids.select do |uuid|
  ts = uuid.timestamp
  ts && ts >= start_time && ts <= end_time
end
# => [v7(2024-01-15), v7(2024-01-20)]
```

### Group by time period

```ruby
uuids = 100.times.map { Fast::UUID.v7 }

# Group by day
grouped = uuids.group_by do |uuid|
  ts = uuid.timestamp
  ts&.strftime("%Y-%m-%d")
end
```

### Timestamp comparison

```ruby
uuid1 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 10, 0, 0))
uuid2 = Fast::UUID.v7(time: Time.utc(2024, 1, 15, 11, 0, 0))

uuid1.timestamp < uuid2.timestamp  # => true
```

## Timezone handling

All timestamps are returned as UTC `Time` objects:

```ruby
uuid = Fast::UUID.v7
timestamp = uuid.timestamp
timestamp.zone  # => "UTC"
```

Convert to local time if needed:

```ruby
timestamp.localtime  # => local timezone
```

## Performance

Timestamp extraction is highly optimized:
- v7 timestamp: ~2 object allocations
- v1/v6 timestamp: ~2 object allocations
- Non-time versions: returns `nil` immediately (no allocation)

## Edge cases

### Nil and Max UUIDs

```ruby
Fast::UUID::NIL.timestamp  # => nil (version 0, not time-based)
Fast::UUID::MAX.timestamp  # => nil (version 15, not time-based)
```

### Unknown versions

```ruby
# Version 2 UUID (not time-based in RFC 9562)
uuid = Fast::UUID.parse("00000000-0000-2000-8000-000000000000")
uuid.timestamp  # => nil
```

### Parsing existing UUIDs

```ruby
# Parse a UUID from a database or API
uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")

# Check if it has a timestamp
if uuid.timestamp
  puts "Created at: #{uuid.timestamp}"
else
  puts "No timestamp available"
end
```
