# frozen_string_literal: true

require "fast/uuid"

describe Fast::UUID do
  let(:uuid) { Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F") }

  it "renders canonical lowercase 8-4-4-4-12, frozen" do
    expect(uuid.to_s).to be(:==, "017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
    expect(uuid.to_s).to be(:frozen?)
    expect(uuid.to_str).to be(:==, uuid.to_s)
  end

  it "interpolates, concatenates and joins as a String" do
    expect("x#{uuid}").to be(:==, "x017f22e2-79b0-7cc3-98c4-dc0c0c07398f") # to_s
    expect(String.new.concat("x", uuid)).to be(:==, "x017f22e2-79b0-7cc3-98c4-dc0c0c07398f") # to_str
    expect(["x", uuid].join).to be(:==, "x017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
  end

  it "renders the URN form" do
    expect(uuid.urn).to be(:==, "urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
  end

  it "renders 32 lowercase hex characters without hyphens" do
    expect(uuid.hex).to be(:==, "017f22e279b07cc398c4dc0c0c07398f")
    expect(uuid.hex.length).to be(:==, 32)
  end

  it "gives frozen 16-byte binary bytes" do
    expect(uuid.bytes.bytesize).to be(:==, 16)
    expect(uuid.bytes).to be(:frozen?)
    expect(uuid.bytes.encoding).to be(:==, Encoding::BINARY)
    expect(uuid.bytes.unpack1("H*")).to be(:==, uuid.hex)
  end

  it "builds from 16 bytes and round-trips" do
    expect(Fast::UUID.new(uuid.bytes)).to be(:==, uuid)
    expect(Fast::UUID.new(uuid.bytes).to_s).to be(:==, uuid.to_s)
  end

  it "accepts a 16-byte String of any encoding tag and normalizes it to binary" do
    utf8 = [uuid.hex].pack("H*").force_encoding(Encoding::UTF_8)
    expect(Fast::UUID.new(utf8).bytes.encoding).to be(:==, Encoding::BINARY)
    expect(Fast::UUID.new(utf8)).to be(:==, uuid)
  end

  it "rejects everything else from new" do
    ["017f22e2-79b0-7cc3-98c4-dc0c0c07398f", # a String, but 36 bytes
     "017f22e2", # a String, but 9 bytes
     "", nil, 42, 16.times.to_a].each do |value|
      expect { Fast::UUID.new(value) }.to raise_exception(ArgumentError)
    end
  end

  it "builds from anything carrying the 16 bytes via to_str, and rejects wrong sizes and no to_str" do
    carrier = Object.new
    def carrier.to_str
      Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f").bytes
    end

    expect(Fast::UUID.new(carrier)).to be(:==, uuid)

    short = Object.new
    def short.to_str
      "short"
    end

    expect { Fast::UUID.new(short) }.to raise_exception(ArgumentError)

    no_bytes = Class.new(BasicObject).new
    expect { Fast::UUID.new(no_bytes) }.to raise_exception(ArgumentError)
  end

  it "is immutable: the constants and every instance are frozen" do
    expect(Fast::UUID::NIL).to be(:frozen?)
    expect(Fast::UUID::MAX).to be(:frozen?)
    expect(Fast::UUID.v4).to be(:frozen?)
  end
end
