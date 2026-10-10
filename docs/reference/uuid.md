# Reference: Fast::UUID

`Fast::UUID` is one immutable, frozen value class: generate v4/v7 and name-based v3/v5,
parse and validate every RFC 9562 version and variant, compare as an opaque 128-bit
value. It includes
`Comparable` and defines `==`, `eql?` and `hash` over the 128-bit value alone — case,
provenance and version are irrelevant to identity.

## Class methods

| Signature | Returns | Notes |
|---|---|---|
| `parse(str)` | `Fast::UUID` | Parses a String in the RFC §4 canonical form, `4hexOctet-2hexOctet-2hexOctet-2hexOctet-6hexOctet`, case-insensitive. Validity is that grammar and nothing more: any version and any variant parses, Nil and Max included. Raises `Fast::UUID::ParseError` for a non-conforming String and `TypeError` for a non-String. See [Why validity is the grammar and nothing more](../explanation/validity.md). |
| `parse?(str)` | `Fast::UUID` or `nil` | `parse` without raising: nil for every rejection, wrong type included. |
| `valid?(str)` | Boolean | The same grammar, as a check: true for a conforming String, false otherwise. |
| `new(bytes)` | `Fast::UUID` | Builds from a 16-byte binary String; raises `ArgumentError` otherwise. An encoding tag on a 16-byte input is normalized to binary. |
| `v3(namespace, name)` | `Fast::UUID` | MD5 over the namespace's 16 bytes followed by the name's, the whole 128-bit digest masked into place: version 3, `10xx` variant. Same namespace and name, same UUID — across processes, machines and years. Where possible, the RFC says, prefer v5 over v3: MD5's collisions are practical. See [How to generate deterministic UUIDs for tests](../how-to/generate-deterministic-uuids-for-tests.md). |
| `v4` | `Fast::UUID` | 122 random bits from the CSPRNG (`SecureRandom`), version 4, `10xx` variant. |
| `v5(namespace, name)` | `Fast::UUID` | SHA-1 over the same input as v3, the leftmost 128 bits of its 160-bit digest (the rightmost 32 discarded) masked into place: version 5, `10xx` variant. Same namespace and name, same UUID. |
| `v7(time: Time.now)` | `Fast::UUID` | 48-bit big-endian `unix_ts_ms` from `time` (sub-millisecond input truncated), version 7, 12-bit `rand_a` and 62-bit `rand_b` fully random — 74 random bits, no counter, no shared state, thread-safe. See [How to generate deterministic UUIDs for tests](../how-to/generate-deterministic-uuids-for-tests.md). |
| `generate` | `Fast::UUID` | v7, the RFC's recommended default. |

## Instance methods

| Signature | Returns | Notes |
|---|---|---|
| `version` | `Integer` | The version nibble, 0–15, whatever it is: 1 Gregorian time, 3 MD5, 4 random, 5 SHA-1, 6 reordered Gregorian, 7 Unix-epoch time, 8 custom. Unknown versions are reported, not rejected. |
| `variant` | `Symbol` | `:rfc9562` when the top two bits are `10`, `:ncs` for `0xxx` (holds Nil), `:microsoft` for `110x`, `:future` for `111x` (holds Max). |
| `timestamp` | `Time` or `nil` | UTC. v1 and v6: the 60-bit 100-ns Gregorian timestamp (baseline 1582-10-15). v7: `unix_ts_ms`. Every other version, nil. |
| `to_s` / `to_str` | `String` | The canonical form, lowercase 8-4-4-4-12, frozen. `to_str` makes it interchangeable with Strings. |
| `bytes` | `String` | The 128-bit value as a frozen 16-byte binary String; see [How to store a UUID as 16 bytes](../how-to/store-a-uuid-as-16-bytes.md). |
| `hex` | `String` | 32 lowercase hex characters, no hyphens. |
| `urn` | `String` | `"urn:uuid:"` followed by the canonical form. |
| `nil_uuid?` | Boolean | The value equals all 128 zero bits. |
| `max_uuid?` | Boolean | The value equals all 128 one bits. |
| `==(other)` / `eql?(other)` | Boolean | Same 128-bit value. A UUID from `parse` and one from `new(bytes)` are equal. |
| `hash` | `Integer` | Consistent with `==`; equal values hash equal, so UUIDs key Hashes and live in Sets. |
| `<=>(other)` | `Integer` or `nil` | Opaque unsigned 128-bit byte order (RFC §6.11): v6 and v7 sort chronologically, v1 does not. nil for a non-UUID. See [In what order UUIDs sort](../explanation/comparison-order.md). |

## Constants

| Constant | Value |
|---|---|
| `Fast::UUID::NIL` | All 128 bits zero. Variant `:ncs`, version 0. |
| `Fast::UUID::MAX` | All 128 bits one. Variant `:future`, version 15. |
| `Fast::UUID::NAMESPACE_DNS` | The RFC §6.6 DNS namespace, `6ba7b810-9dad-11d1-80b4-00c04fd430c8`. |
| `Fast::UUID::NAMESPACE_URL` | The RFC §6.6 URL namespace, `6ba7b811-9dad-11d1-80b4-00c04fd430c8`. |
| `Fast::UUID::NAMESPACE_OID` | The RFC §6.6 OID namespace, `6ba7b812-9dad-11d1-80b4-00c04fd430c8`. |
| `Fast::UUID::NAMESPACE_X500` | The RFC §6.6 X.500 namespace, `6ba7b814-9dad-11d1-80b4-00c04fd430c8`. |
| `Fast::UUID::CANONICAL` | The validity Regexp: the RFC §4 ABNF, case-insensitive. |
| `Fast::UUID::GREGORIAN_OFFSET` | 100-ns ticks between the Gregorian epoch (1582-10-15) and the Unix epoch, for v1/v6 timestamps. |
| `Fast::UUID::VERSION` | The gem's version String. |

## Errors

| Class | Raised when |
|---|---|
| `Fast::UUID::Error` (`< StandardError`) | The base class of every error this gem raises; rescue it to catch both of the below. |
| `Fast::UUID::ParseError` (`< Fast::UUID::Error`) | `parse` was given a String that does not conform to the RFC §4 grammar, or `v3`/`v5` a namespace String that does not conform. |
| `::TypeError` | `parse` was given a non-String, or `v3`/`v5` a non-String name or a namespace that is neither a `Fast::UUID` nor a String. |
| `::ArgumentError` | `new` was given anything but a 16-byte String. |
