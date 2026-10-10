# frozen_string_literal: true

require "fast/uuid"

describe Fast::UUID do
  def canonical?(uuid)
    string = uuid.to_s
    string.length == 36 && string.count("-") == 4 && string.scan(/[^0-9a-f-]/).empty? &&
      string[14] == uuid.version.to_s(16) && %w[8 9 a b].include?(string[19])
  end

  describe ".v4" do
    it "generates version 4 with the 10xx variant" do
      uuid = Fast::UUID.v4
      expect(canonical?(uuid)).to be(:==, true)
      expect(uuid.version).to be(:==, 4)
      expect(uuid.variant).to be(:==, :rfc9562)
      expect(uuid.timestamp).to be_nil
    end

    it "generates distinct UUIDs" do
      many = Array.new(10_000) { Fast::UUID.v4 }
      expect(many.map(&:to_s).uniq.length).to be(:==, 10_000)
    end
  end

  describe ".v7" do
    it "generates version 7 with the 10xx variant" do
      uuid = Fast::UUID.v7
      expect(canonical?(uuid)).to be(:==, true)
      expect(uuid.version).to be(:==, 7)
      expect(uuid.variant).to be(:==, :rfc9562)
    end

    it "carries the injected time to the millisecond, sub-milliseconds truncated" do
      time = Time.utc(2022, 2, 22, 19, 22, 22)
      uuid = Fast::UUID.v7(time: time)
      expect(uuid.timestamp).to be(:==, time)
      expect(uuid.hex[0, 12]).to be(:==, "017f22e279b0")

      uuid = Fast::UUID.v7(time: time + 0.000999)
      expect(uuid.timestamp).to be(:==, time)

      uuid = Fast::UUID.v7(time: time + Rational(1, 1000))
      expect(uuid.timestamp).to be(:==, time + Rational(1, 1000))
    end

    it "gives distinct fully random tails within one millisecond" do
      time = Time.utc(2022, 2, 22, 19, 22, 22)
      many = Array.new(10_000) { Fast::UUID.v7(time: time) }
      expect(many.map(&:to_s).uniq.length).to be(:==, 10_000)
      expect(many.map(&:timestamp).uniq.length).to be(:==, 1)
    end

    it "orders later milliseconds greater" do
      time = Time.utc(2022, 2, 22, 19, 22, 22)
      expect(Fast::UUID.v7(time: time)).to be(:<, Fast::UUID.v7(time: time + 1))
      expect(Fast::UUID.v7(time: time + 1)).to be(:>, Fast::UUID.v7(time: time))
    end

    it "defaults to now" do
      expect(Fast::UUID.v7.timestamp).to be_within(1).of(Time.now.utc)
    end
  end

  describe ".generate" do
    it "defaults to v7, the RFC's recommended default" do
      expect(Fast::UUID.generate.version).to be(:==, 7)
    end
  end

  it "generates distinct well-formed UUIDs across threads" do
    uuids = Array.new(8) do
      Thread.new { Array.new(250) { Fast::UUID.v7 } }
    end.flat_map(&:value)
    expect(uuids.map(&:to_s).uniq.length).to be(:==, 2_000)
    expect(uuids.all? { |uuid| canonical?(uuid) }).to be(:==, true)
  end
end
