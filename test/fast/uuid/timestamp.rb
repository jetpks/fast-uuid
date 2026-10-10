# frozen_string_literal: true

require "fast/uuid"

describe Fast::UUID do
  let(:time) { Time.utc(2022, 2, 22, 19, 22, 22) }

  it "reads the v1 60-bit 100-ns Gregorian timestamp" do
    vector = Fast::UUID.parse("C232AB00-9414-11EC-B3C8-9F6BDECED846")
    expect(vector.timestamp).to be(:==, time)
    expect(vector.timestamp.zone).to be(:==, "UTC")
  end

  it "reads the v6 60-bit 100-ns Gregorian timestamp, fields in descending significance" do
    vector = Fast::UUID.parse("1EC9414C-232A-6B00-B3C8-9F6BDECED846")
    expect(vector.timestamp).to be(:==, time)
    expect(vector.timestamp.zone).to be(:==, "UTC")
  end

  it "reads the v7 unix_ts_ms" do
    vector = Fast::UUID.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
    expect(vector.timestamp).to be(:==, time)
    expect(vector.timestamp.zone).to be(:==, "UTC")
  end

  it "keeps v7 sub-millisecond precision where the time carried it" do
    uuid = Fast::UUID.v7(time: time + Rational(25, 10_000))
    expect(uuid.timestamp).to be(:==, time + Rational(2, 1000))
  end

  it "gives no timestamp to non-time versions" do
    # v0, v2, v3, v4, v5, v8 and the unknown v15.
    %w[00000000-0000-0000-8000-000000000000 00000000-0000-2000-8000-000000000000
       5df41881-3aed-3515-88a7-2f4a814cf09e 919108f7-52d1-4320-9bac-f847db4148a8
       2ed6657d-e927-568b-95e1-2665a8aea6a2 00000000-0000-8000-8000-000000000000
       ffffffff-ffff-ffff-8fff-ffffffffffff].each do |string|
      expect(Fast::UUID.parse(string).timestamp).to be_nil
    end
  end
end
