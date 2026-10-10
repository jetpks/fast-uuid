# frozen_string_literal: true

require "securerandom"

module Fast
  # An immutable, frozen RFC 9562 UUID value: generate v4/v7, parse and
  # validate every version and variant, compare as an opaque 128-bit value.
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

    # The RFC's recommended default: v7.
    def self.generate
      v7
    end

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
