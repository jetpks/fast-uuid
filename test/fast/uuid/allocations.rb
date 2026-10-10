# frozen_string_literal: true

require "fast/uuid"

# Allocation budgets for parse, generate and the render paths: what one
# operation costs in Ruby objects beyond the UUID itself. Counts are
# GC.stat, exact and the same on every platform. Everything a measured
# block touches is a local: a `let` costs an object per read. Measured on
# Ruby 4.0.7, then frozen: parse 6, v4 12, v7 12, to_s and the comparisons
# 0, hex and urn 1, the v7 timestamp 2 and the v1 timestamp 10.
describe "allocations" do
  # Objects allocated per run of the block, averaged over +times+ runs so a
  # one-off allocation outside the block (GC.stat's own, under coverage)
  # does not count.
  def allocations(times = 100, &block)
    before = GC.stat(:total_allocated_objects)
    times.times(&block)
    (GC.stat(:total_allocated_objects) - before) / times.to_f
  end

  it "parses in six objects: the dehyphenated text, the bytes, the binary copy, the hex and the canonical form" do
    string = "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
    Fast::UUID.parse(string)
    expect(allocations { Fast::UUID.parse(string) }).to be(:<, 7)
  end

  it "generates v4 in twelve objects" do
    Fast::UUID.v4
    expect(allocations { Fast::UUID.v4 }).to be(:<, 13)
  end

  it "generates v7 in twelve objects" do
    Fast::UUID.v7
    expect(allocations { Fast::UUID.v7 }).to be(:<, 13)
  end

  it "renders to_s for free" do
    uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
    expect(allocations { uuid.to_s }).to be(:<, 1)
  end

  it "renders hex and urn for one object" do
    uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
    expect(allocations { uuid.hex }).to be(:<, 2)
    expect(allocations { uuid.urn }).to be(:<, 2)
  end

  it "compares and hashes for free" do
    uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
    other = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
    expect(allocations { uuid == other }).to be(:<, 1)
    expect(allocations { uuid <=> other }).to be(:<, 1)
    expect(allocations { uuid.hash }).to be(:<, 1)
  end

  it "reads the v7 timestamp for two objects" do
    uuid = Fast::UUID.parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
    expect(allocations { uuid.timestamp }).to be(:<, 3)
  end
end
