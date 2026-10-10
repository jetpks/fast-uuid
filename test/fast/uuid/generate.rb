# frozen_string_literal: true

require "fast/uuid"

describe Fast::UUID do
  def no_integer_or_string_form
    Class.new(BasicObject).new
  end

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

    it "accepts an Integer-like node and clock_sequence, and a 6-byte string-like node, converting to the same UUID" do
      int_clock = Object.new
      def int_clock.to_int
        0x33C8
      end

      int_node = Object.new
      def int_node.to_int
        0x9F6BDECED846
      end

      mac_node = Object.new
      def mac_node.to_s
        "\x9f\x6b\xde\xce\xd8\x46".b
      end

      fields = { time: time, clock_sequence: 0x33C8, node: 0x9F6BDECED846 }
      expect(Fast::UUID.v1(time: time, clock_sequence: int_clock, node: int_node)).to be(:==, Fast::UUID.v1(**fields))
      expect(Fast::UUID.v6(time: time, clock_sequence: int_clock, node: int_node)).to be(:==, Fast::UUID.v6(**fields))
      expect(Fast::UUID.v1(time: time, clock_sequence: 0x33C8, node: mac_node)).to be(:==, Fast::UUID.v1(**fields))
      expect(Fast::UUID.v6(time: time, clock_sequence: 0x33C8, node: mac_node)).to be(:==, Fast::UUID.v6(**fields))

      expect(Fast::UUID.v1(time: time, clock_sequence: 0x33C8, node: :abcdef))
        .to be(:==, Fast::UUID.v1(time: time, clock_sequence: 0x33C8, node: "abcdef"))
    end

    it "truncates a Float node and clock_sequence the way Ruby converts Floats to Integers" do
      expect(Fast::UUID.v1(time: time, clock_sequence: 0x33C8, node: 4.2))
        .to be(:==, Fast::UUID.v1(time: time, clock_sequence: 0x33C8, node: 4))
      expect(Fast::UUID.v1(time: time, clock_sequence: 3.7, node: 0x9F6BDECED846))
        .to be(:==, Fast::UUID.v1(time: time, clock_sequence: 3, node: 0x9F6BDECED846))
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

    it "raises TypeError for a node with no Integer or String form, or a string-like one that is not 6 bytes" do
      %i[v1 v6].each do |version|
        ["00" * 5, ["9f6bdeced846"], :multicast, no_integer_or_string_form].each do |node|
          expect { Fast::UUID.public_send(version, node: node) }.to raise_exception(::TypeError)
        end
      end
    end

    it "raises TypeError for a clock_sequence with no Integer form" do
      %i[v1 v6].each do |version|
        ["0", [0x33C8], no_integer_or_string_form].each do |clock_sequence|
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

    def no_string_form
      Class.new(BasicObject).new
    end

    it "raises TypeError for a name or namespace with no String form" do
      %i[v3 v5].each do |version|
        expect { generated(version, Fast::UUID::NAMESPACE_DNS, no_string_form) }.to raise_exception(::TypeError)
        expect { generated(version, no_string_form) }.to raise_exception(::TypeError)
      end
    end

    it "raises ParseError for a namespace whose String form does not conform" do
      %i[v3 v5].each do |version|
        [42, nil, [Fast::UUID::NAMESPACE_DNS.to_s], "not-a-uuid"].each do |namespace|
          expect { generated(version, namespace) }.to raise_exception(Fast::UUID::ParseError)
        end
      end
    end

    it "generates the same UUID from the same namespace and name, however they carry their String form" do
      %i[v3 v5].each do |version|
        expect(generated(version, Fast::UUID::NAMESPACE_DNS, :"www.example.com")).to be(:==, generated(version))
        expect(generated(version, :"6ba7b810-9dad-11d1-80b4-00c04fd430c8")).to be(:==, generated(version))
        expect(generated(version, Fast::UUID::NAMESPACE_DNS, 42))
          .to be(:==, generated(version, Fast::UUID::NAMESPACE_DNS, "42"))
        expect(generated(version, Fast::UUID::NAMESPACE_DNS, nil))
          .to be(:==, generated(version, Fast::UUID::NAMESPACE_DNS, ""))
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
