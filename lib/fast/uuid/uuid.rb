# frozen_string_literal: true

require "digest"
require "securerandom"

module Fast
  # An immutable, frozen RFC 9562 UUID value: generate v4/v7, time-based
  # v1/v6 and name-based v3/v5, parse and validate every version and
  # variant, compare as an opaque 128-bit value.
  class UUID
    include Comparable

    # The canonical form, 4hexOctet-2hexOctet-2hexOctet-2hexOctet-6hexOctet,
    # case-insensitive. Validity is this grammar and nothing more: the RFC
    # defines no version or variant gate, and Nil and Max sit outside the
    # 10xx variant by design.
    CANONICAL = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

    # 100-ns ticks between the Gregorian (1582-10-15) and Unix epoch baselines.
    GREGORIAN_OFFSET = 122_192_928_000_000_000

    # 128 random bits from the CSPRNG, masked into place: 122 stay random,
    # version 4 fills one nibble and the 10xx variant the top two bits.
    def self.v4
      high, low = SecureRandom.bytes(16).unpack("Q> Q>")
      high = (high & 0xFFFFFFFFFFFF0FFF) | 0x4000
      low = (low & 0x3FFFFFFFFFFFFFFF) | 0x8000000000000000
      new([high, low].pack("Q> Q>"))
    end

    # The time is truncated to whole milliseconds for the 48-bit unix_ts_ms;
    # rand_a and rand_b stay fully random, no counter and no shared state.
    def self.v7(time: Time.now)
      high, low = SecureRandom.bytes(16).unpack("Q> Q>")
      milliseconds = (time.to_i * 1000) + (time.nsec / 1_000_000)
      milliseconds &= 0xFFFFFFFFFFFF
      high = (milliseconds << 16) | 0x7000 | (high & 0x0FFF)
      low = (low & 0x3FFFFFFFFFFFFFFF) | 0x8000000000000000
      new([high, low].pack("Q> Q>"))
    end

    # The 60-bit 100-ns Gregorian timestamp both time-based versions
    # encode, masked to the field the way v7 masks unix_ts_ms.
    def self.gregorian_ticks(time)
      ((time.to_i * 10_000_000) + (time.nsec / 100) + GREGORIAN_OFFSET) & 0xFFFFFFFFFFFFFFF
    end

    # The node: nil draws a fresh CSPRNG value with the multicast bit set
    # (RFC §6.10), an Integer masks to 48 bits, a 6-byte String unpacks.
    # The 48 bits travel as hex — a Q> would land past the immediate
    # Integers three times in four and cost an object when it does.
    def self.node_id(node)
      case node
      when nil
        SecureRandom.bytes(6).unpack1("H12").to_i(16) | (1 << 40)
      when Integer
        node & 0xFFFFFFFFFFFF
      when String
        raise TypeError, "a 6-byte node String is required (got #{node.bytesize} bytes)" unless node.bytesize == 6

        node.b.unpack1("H12").to_i(16)
      else
        raise TypeError, "an Integer or 6-byte String node is required (got #{node.class})"
      end
    end

    # The low word v1 and v6 share: the 10xx variant over the 14-bit
    # clock_seq, then the 48-bit node. A nil clock_sequence draws a fresh
    # CSPRNG value, as v4 draws its bits.
    def self.sequence_low(node, clock_sequence)
      unless clock_sequence.nil? || clock_sequence.is_a?(Integer)
        raise TypeError, "an Integer clock_sequence is required (got #{clock_sequence.class})"
      end

      clock_sequence = SecureRandom.bytes(2).unpack1("n") & 0x3FFF if clock_sequence.nil?
      0x8000000000000000 | ((clock_sequence & 0x3FFF) << 48) | node_id(node)
    end

    private_class_method :gregorian_ticks, :node_id, :sequence_low

    # The 60-bit Gregorian timestamp split least-significant-first:
    # time_low, then time_mid, then time_hi under the version nibble 1.
    # Where possible, prefer v7 (RFC §5.7): v1's least significant field
    # sits first, so it does not sort chronologically.
    def self.v1(time: Time.now, node: nil, clock_sequence: nil)
      ticks = gregorian_ticks(time)
      high = ((ticks & 0xFFFFFFFF) << 32) | (((ticks >> 32) & 0xFFFF) << 16) | 0x1000 | (ticks >> 48)
      new([high, sequence_low(node, clock_sequence)].pack("Q> Q>"))
    end

    # v1's timestamp reordered most-significant-first (RFC §5.6, the v1
    # migration version): time_high, then time_mid, then time_low under the
    # version nibble 6. Same node, clock sequence and variant as v1, and it
    # sorts chronologically where v1 does not.
    def self.v6(time: Time.now, node: nil, clock_sequence: nil)
      ticks = gregorian_ticks(time)
      high = ((ticks >> 28) << 32) | (((ticks >> 12) & 0xFFFF) << 16) | 0x6000 | (ticks & 0xFFF)
      new([high, sequence_low(node, clock_sequence)].pack("Q> Q>"))
    end

    # MD5 over the namespace's 16 bytes followed by the name's, the whole
    # 128-bit digest masked into place: version 3 fills one nibble and the
    # 10xx variant the top two bits. Where possible, prefer v5.
    def self.v3(namespace, name)
      high, low = Digest::MD5.digest(digest_input(namespace, name)).unpack("Q> Q>")
      high = (high & 0xFFFFFFFFFFFF0FFF) | 0x3000
      low = (low & 0x3FFFFFFFFFFFFFFF) | 0x8000000000000000
      new([high, low].pack("Q> Q>"))
    end

    # SHA-1 over the same input, the leftmost 128 bits of its 160-bit digest
    # (the rightmost 32 discarded) masked into place: version 5, the 10xx
    # variant.
    def self.v5(namespace, name)
      high, low = Digest::SHA1.digest(digest_input(namespace, name)).byteslice(0, 16).unpack("Q> Q>")
      high = (high & 0xFFFFFFFFFFFF0FFF) | 0x5000
      low = (low & 0x3FFFFFFFFFFFFFFF) | 0x8000000000000000
      new([high, low].pack("Q> Q>"))
    end

    # The RFC's recommended default: v7.
    def self.generate
      v7
    end

    # The input of both name-based versions: the namespace's 16 bytes
    # followed by the name's. A String namespace parses, any other non-UUID
    # raises TypeError, as does a non-String name.
    def self.digest_input(namespace, name)
      raise TypeError, "a String name is required (got #{name.class})" unless name.is_a?(String)

      namespace = parse(namespace) unless namespace.is_a?(UUID)
      namespace.bytes + name.b
    end

    private_class_method :digest_input

    def self.parse(str)
      raise TypeError, "no implicit conversion of #{str.class} into Fast::UUID" unless str.is_a?(String)
      raise ParseError, "not a valid UUID: #{str}" unless CANONICAL.match?(str)

      new([str.delete("-")].pack("H*"))
    end

    def self.parse?(str)
      parse(str)
    rescue TypeError, ParseError
      nil
    end

    def self.valid?(str)
      str.is_a?(String) && CANONICAL.match?(str)
    end

    # From a 16-byte binary String; an encoding tag on the input is
    # normalized to binary, every other ill shape raises ArgumentError.
    def initialize(bytes)
      unless bytes.is_a?(String) && bytes.bytesize == 16
        raise ArgumentError, "a 16-byte binary String is required (got #{bytes.class})"
      end

      @bytes = bytes.b.freeze
      @string = @bytes.unpack1("H*").insert(8, "-").insert(13, "-").insert(18, "-").insert(23, "-").freeze
      freeze
    end

    def version
      @bytes.getbyte(6) >> 4
    end

    def variant
      case @bytes.getbyte(8) >> 5
      when 0b100, 0b101 then :rfc9562
      when 0b110 then :microsoft
      when 0b111 then :future
      else :ncs
      end
    end

    def timestamp
      case version
      when 1
        # time_low, time_mid, then time_hi_and_version on the wire.
        gregorian(((@bytes[6, 2].unpack1("n") & 0x0FFF) << 48) | (@bytes[4, 2].unpack1("n") << 32) |
                  @bytes[0, 4].unpack1("N"))
      when 6
        # time_high, time_mid, time_low in descending order of significance.
        gregorian((@bytes[0, 4].unpack1("N") << 28) | (@bytes[4, 2].unpack1("n") << 12) |
                  (@bytes[6, 2].unpack1("n") & 0x0FFF))
      when 7
        milliseconds = @bytes[0, 8].unpack1("Q>") >> 16
        Time.at(milliseconds / 1000, (milliseconds % 1000) * 1_000_000, :nanosecond).utc
      end
    end

    attr_reader :bytes

    def to_s
      @string
    end

    alias to_str to_s

    def hex
      @bytes.unpack1("H*")
    end

    def urn
      "urn:uuid:#{@string}"
    end

    def nil_uuid?
      self == NIL
    end

    def max_uuid?
      self == MAX
    end

    def ==(other)
      other.is_a?(UUID) && other.bytes == bytes
    end

    alias eql? ==

    def hash
      bytes.hash
    end

    # Opaque unsigned 128-bit byte order: v6 and v7 sort chronologically as
    # raw bytes; v1 does not, its time_low sits first.
    def <=>(other)
      bytes <=> other.bytes if other.is_a?(UUID)
    end

    private

    def gregorian(ticks)
      unix_ticks = ticks - GREGORIAN_OFFSET
      Time.at(unix_ticks / 10_000_000, (unix_ticks % 10_000_000) * 100, :nanosecond).utc
    end
  end
end

Fast::UUID::NIL = Fast::UUID.new(("\0" * 16).b)
Fast::UUID::MAX = Fast::UUID.new(("\xFF" * 16).b)
Fast::UUID::NAMESPACE_DNS = Fast::UUID.parse("6ba7b810-9dad-11d1-80b4-00c04fd430c8")
Fast::UUID::NAMESPACE_URL = Fast::UUID.parse("6ba7b811-9dad-11d1-80b4-00c04fd430c8")
Fast::UUID::NAMESPACE_OID = Fast::UUID.parse("6ba7b812-9dad-11d1-80b4-00c04fd430c8")
Fast::UUID::NAMESPACE_X500 = Fast::UUID.parse("6ba7b814-9dad-11d1-80b4-00c04fd430c8")
