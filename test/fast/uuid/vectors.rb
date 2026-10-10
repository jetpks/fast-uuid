# frozen_string_literal: true

require "fast/uuid"

# The six test vectors of RFC 9562 Appendix A, exactly as quoted there,
# mixed case and all.
VECTORS = {
  v1: ["C232AB00-9414-11EC-B3C8-9F6BDECED846", 1, "2022-02-22T19:22:22Z"],
  v3: ["5df41881-3aed-3515-88a7-2f4a814cf09e", 3, nil],
  v4: ["919108f7-52d1-4320-9bac-f847db4148a8", 4, nil],
  v5: ["2ed6657d-e927-568b-95e1-2665a8aea6a2", 5, nil],
  v6: ["1EC9414C-232A-6B00-B3C8-9F6BDECED846", 6, "2022-02-22T19:22:22Z"],
  v7: ["017F22E2-79B0-7CC3-98C4-DC0C0C07398F", 7, "2022-02-22T19:22:22Z"]
}.freeze

describe "RFC 9562 Appendix A test vectors" do
  VECTORS.each do |name, (string, version, timestamp)|
    it "parses the #{name} vector" do
      uuid = Fast::UUID.parse(string)
      expect(uuid.version).to be(:==, version)
      expect(uuid.variant).to be(:==, :rfc9562)
      expect(uuid.timestamp&.utc&.strftime("%Y-%m-%dT%H:%M:%SZ")).to be(:==, timestamp)
    end
  end

  # A.1 and A.5 share every field but the timestamp's wire order: the same
  # time, clock sequence and node generate both.
  describe "the v1 and v6 vectors, generated" do
    it "generates the v1 vector from the shared fields" do
      uuid = Fast::UUID.v1(time: Time.utc(2022, 2, 22, 19, 22, 22), clock_sequence: 0x33C8, node: 0x9F6BDECED846)
      expect(uuid.to_s).to be(:==, "c232ab00-9414-11ec-b3c8-9f6bdeced846")
      expect(uuid.version).to be(:==, 1)
      expect(uuid.variant).to be(:==, :rfc9562)
      expect(uuid.timestamp).to be(:==, Time.utc(2022, 2, 22, 19, 22, 22))
    end

    it "generates the v6 vector from the same fields, timestamp reordered" do
      uuid = Fast::UUID.v6(time: Time.utc(2022, 2, 22, 19, 22, 22), clock_sequence: 0x33C8, node: 0x9F6BDECED846)
      expect(uuid.to_s).to be(:==, "1ec9414c-232a-6b00-b3c8-9f6bdeced846")
      expect(uuid.version).to be(:==, 6)
      expect(uuid.variant).to be(:==, :rfc9562)
      expect(uuid.timestamp).to be(:==, Time.utc(2022, 2, 22, 19, 22, 22))
    end
  end

  # A.2 and A.4 are the DNS namespace and the name "www.example.com": the
  # name-based versions generate them, not just parse them.
  describe "the v3 and v5 vectors, generated" do
    it "generates the v3 vector from the DNS namespace" do
      uuid = Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com")
      expect(uuid.to_s).to be(:==, "5df41881-3aed-3515-88a7-2f4a814cf09e")
      expect(uuid.version).to be(:==, 3)
      expect(uuid.variant).to be(:==, :rfc9562)
      expect(uuid.timestamp).to be_nil
    end

    it "generates the v5 vector from the DNS namespace" do
      uuid = Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
      expect(uuid.to_s).to be(:==, "2ed6657d-e927-568b-95e1-2665a8aea6a2")
      expect(uuid.version).to be(:==, 5)
      expect(uuid.variant).to be(:==, :rfc9562)
      expect(uuid.timestamp).to be_nil
    end
  end
end
