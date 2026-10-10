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

  describe ".v1 and .v6" do
    let(:time) { Time.utc(2022, 2, 22, 19, 22, 22) }

    it "generates versions 1 and 6 with the 10xx variant" do
      v1 = Fast::UUID.v1(time: time)
      expect(canonical?(v1)).to be(:==, true)
      expect(v1.version).to be(:==, 1)
      expect(v1.variant).to be(:==, :rfc9562)
      v6 = Fast::UUID.v6(time: time)
      expect(canonical?(v6)).to be(:==, true)
      expect(v6.version).to be(:==, 6)
      expect(v6.variant).to be(:==, :rfc9562)
    end

    it "carries the injected time to the 100-ns tick grid, finer than v7's millisecond" do
      sub_second = Time.at(time.to_i, 123_456_700, :nanosecond)
      expect(Fast::UUID.v1(time: sub_second).timestamp).to be(:==, sub_second)
      expect(Fast::UUID.v6(time: sub_second).timestamp).to be(:==, sub_second)
    end

    it "is fully determined by the injected arguments, node and clock sequence included" do
      fields = { time: time, clock_sequence: 0x33C8, node: 0x9F6BDECED846 }
      expect(Fast::UUID.v1(**fields)).to be(:==, Fast::UUID.v1(**fields))
      expect(Fast::UUID.v6(**fields)).to be(:==, Fast::UUID.v6(**fields))
    end

    it "masks an injected node to 48 bits and a clock sequence to 14" do
      v1 = Fast::UUID.v1(time: time, node: 0xFFFFFFFFFFFFFFFF, clock_sequence: 0xFFFF)
      expect(v1.hex[16, 20]).to be(:==, "bfffffffffffffff")
    end

    it "defaults the node to a multicast-marked CSPRNG value and the clock sequence to random" do
      # The multicast bit is the LSB of the node's first octet, octet 10.
      expect(Fast::UUID.v1(time: time).bytes.getbyte(10) & 1).to be(:==, 1)
      expect(Fast::UUID.v6(time: time).bytes.getbyte(10) & 1).to be(:==, 1)
    end

    it "gives distinct UUIDs to consecutive default generations" do
      %i[v1 v6].each do |version|
        many = Array.new(1000) { Fast::UUID.public_send(version) }
        expect(many.map(&:to_s).uniq.length).to be(:==, 1000)
      end
    end

    it "raises TypeError for a node that is neither Integer nor a 6-byte String" do
      %i[v1 v6].each do |version|
        [4.2, "00" * 5, ["9f6bdeced846"], :multicast].each do |node|
          expect { Fast::UUID.public_send(version, node: node) }.to raise_exception(::TypeError)
        end
      end
    end

    it "raises TypeError for a non-Integer clock_sequence" do
      %i[v1 v6].each do |version|
        ["0", 4.2, [0x33C8]].each do |clock_sequence|
          expect { Fast::UUID.public_send(version, clock_sequence: clock_sequence) }.to raise_exception(::TypeError)
        end
      end
    end
  end

  describe ".v3 and .v5" do
    def generated(version, namespace = Fast::UUID::NAMESPACE_DNS, name = "www.example.com")
      Fast::UUID.public_send(version, namespace, name)
    end

    it "generates the same UUID from the same namespace and name, however the namespace is given" do
      %i[v3 v5].each do |version|
        expect(generated(version, Fast::UUID::NAMESPACE_DNS.to_s)).to be(:==, generated(version))
      end
    end

    it "gives a different UUID for a different name" do
      %i[v3 v5].each do |version|
        same = generated(version)
        expect(generated(version, Fast::UUID::NAMESPACE_DNS, "example.com") == same).to be(:==, false)
      end
    end

    it "raises TypeError for a non-String name and for a namespace that is neither UUID nor String" do
      %i[v3 v5].each do |version|
        [42, nil, ["www.example.com"]].each do |name|
          expect { generated(version, Fast::UUID::NAMESPACE_DNS, name) }.to raise_exception(::TypeError)
        end
        [42, nil, [Fast::UUID::NAMESPACE_DNS.to_s]].each do |namespace|
          expect { generated(version, namespace) }.to raise_exception(::TypeError)
        end
      end
    end

    it "raises ParseError for a non-conforming String namespace" do
      %i[v3 v5].each do |version|
        expect { generated(version, "not-a-uuid") }.to raise_exception(Fast::UUID::ParseError)
      end
    end
  end

  describe ".generate" do
    it "defaults to v7, the RFC's recommended default" do
      expect(Fast::UUID.generate.version).to be(:==, 7)
    end
  end

  it "generates distinct well-formed UUIDs across threads" do
    uuids = Array.new(8) do
      Thread.new { Array.new(250) { [Fast::UUID.v7, Fast::UUID.v1, Fast::UUID.v6].sample } }
    end.flat_map(&:value)
    expect(uuids.map(&:to_s).uniq.length).to be(:==, 2_000)
    expect(uuids.all? { |uuid| canonical?(uuid) }).to be(:==, true)
  end
end
