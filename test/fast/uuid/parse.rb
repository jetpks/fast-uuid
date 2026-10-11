# frozen_string_literal: true

require "fast/uuid"

describe Fast::UUID do
  let(:blank) { Class.new(BasicObject).new }

  describe ".parse" do
    it "accepts the canonical form in any case" do
      upper = "017F22E2-79B0-7CC3-98C4-DC0C0C07398F"
      lower = upper.downcase
      expect(Fast::UUID.parse(upper).to_s).to be(:==, lower)
      expect(Fast::UUID.parse(lower).to_s).to be(:==, lower)
    end

    it "rejects every malformed shape with ParseError" do
      # Empty; a fragment; hyphenless; one hex short; one hex long; hyphen
      # shifted; trailing and leading hyphen; not hex, first and last char;
      # braced; URN form; trailing newline.
      ["", "017f22e2", "017f22e279b0", "017f22e2-79b0-7cc3-98c4-dc0c0c07398",
       "017f22e2-79b0-7cc3-98c4-dc0c0c07398ff", "017f22e2-79b07cc3-98c4-dc0c0c07398f",
       "017f22e2-79b0-7cc3-98c4-dc0c0c07398f-", "-017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
       "g17f22e2-79b0-7cc3-98c4-dc0c0c07398f", "017f22e2-79b0-7cc3-98c4-dc0c0c07398g",
       "{017f22e2-79b0-7cc3-98c4-dc0c0c07398f}", "urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
       "017f22e2-79b0-7cc3-98c4-dc0c0c07398f\n"].each do |string|
        expect { Fast::UUID.parse(string) }.to raise_exception(Fast::UUID::ParseError)
      end
    end

    it "accepts anything string-like, converting with #to_s" do
      string = "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
      carrier = Object.new
      def carrier.to_s
        "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
      end
      [string, :"017f22e2-79b0-7cc3-98c4-dc0c0c07398f", carrier].each do |value|
        expect(Fast::UUID.parse(value).to_s).to be(:==, string)
        expect(Fast::UUID.valid?(value)).to be(:==, true)
      end
    end

    it "raises ParseError for a string-like whose #to_s does not conform" do
      [nil, 42, ["017f22e2-79b0-7cc3-98c4-dc0c0c07398f"]].each do |value|
        expect { Fast::UUID.parse(value) }.to raise_exception(Fast::UUID::ParseError)
      end
    end

    it "raises TypeError for an object with no #to_s" do
      expect { Fast::UUID.parse(blank) }.to raise_exception(::TypeError)
    end
  end

  describe ".parse?" do
    it "answers the UUID or nil" do
      string = "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
      expect(Fast::UUID.parse?(string).version).to be(:==, 7)
      expect(Fast::UUID.parse?("gibberish")).to be_nil
      expect(Fast::UUID.parse?(:"not-a-uuid")).to be_nil
      expect(Fast::UUID.parse?(42)).to be_nil
      expect(Fast::UUID.parse?(blank)).to be_nil
    end
  end

  describe ".valid?" do
    it "answers the RFC 4 grammar and nothing more" do
      expect(Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")).to be(:==, true)
      expect(Fast::UUID.valid?("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")).to be(:==, true)
      expect(Fast::UUID.valid?("00000000-0000-0000-0000-000000000000")).to be(:==, true) # Nil parses
      expect(Fast::UUID.valid?("ffffffff-ffff-ffff-ffff-ffffffffffff")).to be(:==, true) # Max parses
      expect(Fast::UUID.valid?("017f22e2-79b0-7cc3-98c4-dc0c0c07398f ")).to be(:==, false)
      expect(Fast::UUID.valid?("not-a-uuid")).to be(:==, false)
      expect(Fast::UUID.valid?(nil)).to be(:==, false)
      expect(Fast::UUID.valid?(42)).to be(:==, false)
      expect(Fast::UUID.valid?(blank)).to be(:==, false)
    end

    it "never rejects on version or variant" do
      # Version 0, NCS variant; version 9, Microsoft; version 15, RFC,
      # Microsoft and Future variants.
      %w[ffffffff-ffff-0fff-0fff-ffffffffffff ffffffff-ffff-9fff-4fff-ffffffffffff
         ffffffff-ffff-ffff-8fff-ffffffffffff ffffffff-ffff-ffff-cfff-ffffffffffff
         ffffffff-ffff-ffff-ffff-ffffffffffff].each do |string|
        expect(Fast::UUID.valid?(string)).to be(:==, true)
      end
    end
  end

  it "parses unknown versions and reports their nibble" do
    [0, 2, 8, 9, 15].each do |version|
      uuid = Fast::UUID.parse("ffffffff-ffff-#{version.to_s(16)}fff-8fff-ffffffffffff")
      expect(uuid.version).to be(:==, version)
      expect(uuid.variant).to be(:==, :rfc9562)
    end
  end
end
