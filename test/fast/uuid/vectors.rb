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
end
