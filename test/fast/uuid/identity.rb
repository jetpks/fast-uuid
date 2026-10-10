# frozen_string_literal: true

require "fast/uuid"

describe Fast::UUID do
  let(:nil_uuid) { Fast::UUID::NIL }
  let(:max_uuid) { Fast::UUID::MAX }

  it "orders Nil, any and Max in opaque unsigned 128-bit byte order" do
    uuid = Fast::UUID.v4
    expect(nil_uuid).to be(:<, uuid)
    expect(uuid).to be(:<, max_uuid)
    expect(nil_uuid).to be(:<, max_uuid)
    expect(uuid <=> Fast::UUID.new(uuid.bytes)).to be(:==, 0)
    expect(uuid <=> nil_uuid).to be(:==, 1)
    expect(nil_uuid <=> uuid).to be(:==, -1)
  end

  it "sorts v7 chronologically as raw bytes" do
    time = Time.utc(2022, 2, 22, 19, 22, 22)
    sorted = [Fast::UUID.v7(time: time + 2), Fast::UUID.v7(time: time), Fast::UUID.v7(time: time + 1)].sort
    expect(sorted.map(&:timestamp)).to be(:==, [time, time + 1, time + 2])
  end

  it "compares by the 128-bit value alone, provenance irrelevant" do
    parsed = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
    from_bytes = Fast::UUID.new(parsed.bytes)
    expect(parsed).to be(:==, from_bytes)
    expect(parsed).to be(:eql?, from_bytes)
    expect(parsed.hash).to be(:==, from_bytes.hash)
    other = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398e")
    expect(parsed).not.to be(:==, other)
    expect(parsed.hash).not.to be(:==, other.hash)
    expect(parsed.hash).not.to be(:==, max_uuid.hash)
  end

  it "does not equal or compare against non-UUIDs" do
    uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
    expect(uuid).not.to be(:==, uuid.to_s)
    expect(uuid.eql?(uuid.to_s)).to be(:==, false)
    expect(uuid <=> uuid.to_s).to be_nil
  end

  it "answers Nil and Max" do
    expect(nil_uuid.nil_uuid?).to be(:==, true)
    expect(nil_uuid.max_uuid?).to be(:==, false)
    expect(max_uuid.max_uuid?).to be(:==, true)
    expect(max_uuid.nil_uuid?).to be(:==, false)
    expect(nil_uuid.variant).to be(:==, :ncs)
    expect(max_uuid.variant).to be(:==, :future)
    expect(nil_uuid.version).to be(:==, 0)
    expect(max_uuid.version).to be(:==, 15)
  end

  it "reports every variant class" do
    classes = {
      "00000000-0000-0000-0000-000000000000" => :ncs, # 0xxx, holds Nil
      "017f22e2-79b0-7cc3-98c4-dc0c0c07398f" => :rfc9562, # 10xx
      "017f22e2-79b0-7cc3-d8c4-dc0c0c07398f" => :microsoft, # 110x
      "017f22e2-79b0-7cc3-f8c4-dc0c0c07398f" => :future # 111x, holds Max
    }
    classes.each do |string, variant|
      expect(Fast::UUID.parse(string).variant).to be(:==, variant)
    end
  end
end
