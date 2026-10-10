# frozen_string_literal: true

require "fast/uuid"

describe "the string constructors" do
  describe ".uuid_v4" do
    it "renders version 4 with the 10xx variant, parseable" do
      string = Fast::UUID.uuid_v4
      uuid = Fast::UUID.parse(string)
      expect(uuid.version).to be(:==, 4)
      expect(uuid.variant).to be(:==, :rfc9562)
      expect(uuid.to_s).to be(:==, string)
    end

    it "is frozen" do
      expect(Fast::UUID.uuid_v4).to be(:frozen?)
    end

    it "gives distinct UUIDs" do
      many = Array.new(10_000) { Fast::UUID.uuid_v4 }
      expect(many.uniq.length).to be(:==, 10_000)
    end
  end

  describe ".uuid_v7" do
    it "matches .v7's timestamp and version on the same injected time" do
      time = Time.utc(2022, 2, 22, 19, 22, 22)
      # Independent draws: the random tail differs, the stamped fields agree.
      expect(Fast::UUID.uuid_v7(time: time)[0, 15]).to be(:==, Fast::UUID.v7(time: time).to_s[0, 15])
      expect(Fast::UUID.parse(Fast::UUID.uuid_v7(time: time)).version).to be(:==, 7)
    end

    it "carries the injected time to the millisecond" do
      time = Time.utc(2022, 2, 22, 19, 22, 22)
      expect(Fast::UUID.parse(Fast::UUID.uuid_v7(time: time)).timestamp).to be(:==, time)
    end

    it "is frozen and defaults to now" do
      string = Fast::UUID.uuid_v7
      expect(string).to be(:frozen?)
      expect(Fast::UUID.parse(string).timestamp).to be_within(1).of(Time.now.utc)
    end
  end

  describe ".uuid_v1 and .uuid_v6" do
    let(:fields) { { time: Time.utc(2022, 2, 22, 19, 22, 22), clock_sequence: 0x33C8, node: 0x9F6BDECED846 } }

    it "renders the v1 vector" do
      expect(Fast::UUID.uuid_v1(**fields)).to be(:==, "c232ab00-9414-11ec-b3c8-9f6bdeced846")
    end

    it "renders the v6 vector" do
      expect(Fast::UUID.uuid_v6(**fields)).to be(:==, "1ec9414c-232a-6b00-b3c8-9f6bdeced846")
    end

    it "equals the object twins' to_s" do
      expect(Fast::UUID.uuid_v1(**fields)).to be(:==, Fast::UUID.v1(**fields).to_s)
      expect(Fast::UUID.uuid_v6(**fields)).to be(:==, Fast::UUID.v6(**fields).to_s)
    end
  end

  describe ".uuid_v3 and .uuid_v5" do
    it "renders the v3 vector" do
      expect(Fast::UUID.uuid_v3(Fast::UUID::NAMESPACE_DNS, "www.example.com"))
        .to be(:==, "5df41881-3aed-3515-88a7-2f4a814cf09e")
    end

    it "renders the v5 vector" do
      expect(Fast::UUID.uuid_v5(Fast::UUID::NAMESPACE_DNS, "www.example.com"))
        .to be(:==, "2ed6657d-e927-568b-95e1-2665a8aea6a2")
    end

    it "equals the object twins' to_s" do
      expect(Fast::UUID.uuid_v3(Fast::UUID::NAMESPACE_DNS, "www.example.com"))
        .to be(:==, Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com").to_s)
      expect(Fast::UUID.uuid_v5(Fast::UUID::NAMESPACE_DNS, "www.example.com"))
        .to be(:==, Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com").to_s)
    end
  end

  describe ".uuid" do
    it "is the v7 string: the RFC's recommended default" do
      string = Fast::UUID.uuid
      expect(Fast::UUID.parse(string).version).to be(:==, 7)
      expect(Fast::UUID.parse(string).timestamp).to be_within(1).of(Time.now.utc)
      expect(string).to be(:frozen?)
    end

    it "agrees with .generate: both now, both v7" do
      expect(Fast::UUID.parse(Fast::UUID.uuid).timestamp).to be_within(1).of(Fast::UUID.generate.timestamp)
    end
  end

  describe "error parity with the object twins" do
    it "raises TypeError for the same bad node and clock_sequence" do
      %i[uuid_v1 uuid_v6].each do |version|
        [4.2, "00" * 5, ["9f6bdeced846"], :multicast].each do |node|
          expect { Fast::UUID.public_send(version, node: node) }.to raise_exception(::TypeError)
        end
        ["0", 4.2, [0x33C8]].each do |clock_sequence|
          expect { Fast::UUID.public_send(version, clock_sequence: clock_sequence) }.to raise_exception(::TypeError)
        end
      end
    end

    it "raises TypeError for the same bad name and namespace" do
      %i[uuid_v3 uuid_v5].each do |version|
        [42, nil, ["www.example.com"]].each do |name|
          expect { Fast::UUID.public_send(version, Fast::UUID::NAMESPACE_DNS, name) }.to raise_exception(::TypeError)
        end
        [42, nil, [Fast::UUID::NAMESPACE_DNS.to_s]].each do |namespace|
          expect { Fast::UUID.public_send(version, namespace, "www.example.com") }.to raise_exception(::TypeError)
        end
      end
    end
  end
end
