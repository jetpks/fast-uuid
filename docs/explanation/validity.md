# Why validity is the grammar and nothing more

`Fast::UUID.parse` accepts anything string-like when it matches one rule — the RFC 9562
§4[^1] grammar — and rejects it when it doesn't. It never checks the version or the variant. That is
a reading of the RFC, not a lack of rigour, and this page is the reading.

## The one grammar

RFC 9562 §4 gives exactly one textual form, as ABNF:

```text
UUID          = 4hexOctet "-" 2hexOctet "-" 2hexOctet "-" 2hexOctet "-" 6hexOctet
```

Case-insensitivity is part of it — the hex digits are defined case-insensitively — so
`C232AB00-...` and `c232ab00-...` are the same value. The URN, braced and hyphenless
forms appear in the RFC only as informational examples; they are not validated forms,
and fast-uuid does not accept them.

## Why no version or variant gate

A natural-looking check — "a valid UUID has a known version and the `10xx` variant" —
rejects UUIDs the RFC itself specifies:

- **Nil** (all zero bits, §5.9) and **Max** (all one bits, §5.10) are valid UUIDs with
  no meaningful version, and their variants are `0xxx` and `111x`. A variant gate
  rejects both.
- The version nibble has reserved rows beyond the six familiar ones (§4.2 Table 2:
  versions 0, 9 and 15 are unused or future), and the RFC defines no rule for refusing
  them. §6.12 says treat UUIDs opaquely: the version nibble is data to report, not a
  password to check.

So `version` returns whatever nibble is there, `variant` reports one of four values,
and both travel with the parse instead of gating it. Version 15, Nil and Max parse;
[Reference: Fast::UUID](../reference/uuid.md#instance-methods) tabulates what each
reports, and [What a UUID is, and what its versions are](uuid-versions.md) is the tour
of what the nibbles name.

## What a caller adds on top

The RFC leaves semantic checks to the caller, and so does this gem, because only the
caller knows what "one of mine" means. After parsing, ask:

```ruby
uuid = Fast::UUID.parse?(input)
uuid && uuid.version == 7 && uuid.variant == :rfc9562 # => a fast-uuid v7, nil otherwise
```

That is a statement about your system, not about validity. Keeping it out of `parse`
is what lets the same parser accept the RFC's own Appendix A test vectors across all
six versions — [the tutorial](../tutorials/generate-parse-and-sort-uuids.md#3-parse-one-from-the-outside-world)
parses the v1 one in upper case and gets the canonical lower case back.

[^1]: RFC 9562 §4, <https://www.rfc-editor.org/rfc/rfc9562#section-4>
