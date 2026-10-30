# Changelog

## 0.2.0

- Ruby 3.3 support dropped; the floor is now `>= 3.4`; CI matrix 3.4/4.0.

## 0.1.0

- Initial release: `Fast::UUID`, one immutable, frozen value class. Generate
  v4 (122 random bits from `SecureRandom`) and v7 (48-bit `unix_ts_ms` plus
  74 fully random bits, no counter and no shared state, thread-safe), with
  `generate` defaulting to v7. Parse and validate every RFC 9562 version and
  variant — validity is the RFC 4 grammar and nothing more, case-insensitive,
  Nil and Max included — with `parse`, `parse?` and `valid?`. `Fast::UUID.new`
  builds from a 16-byte binary String.
- Timestamps: v1 and v6 read their 60-bit 100-ns Gregorian timestamp, v7 its
  `unix_ts_ms`; every other version reports nil. Comparison is opaque
  unsigned 128-bit byte order, so v6 and v7 sort chronologically; v1 does
  not, its `time_low` sits first, and the README carries the caveat.
- `to_s`, `to_str`, `bytes`, `hex`, `urn`, `nil_uuid?`, `max_uuid?`,
  `version`, `variant`, and `==`/`eql?`/`hash` over the 128-bit value alone.
  Verified in-suite against all six RFC 9562 Appendix A test vectors.
