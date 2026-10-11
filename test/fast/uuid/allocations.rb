# frozen_string_literal: true

require "fast/uuid"

# Allocation budgets for parse, generate and the render paths: what one
# operation costs in Ruby objects beyond the UUID itself. Counts are
# GC.stat, exact and the same on every platform. Everything a measured
# block touches is a local: a `let` costs an object per read. Measured on
# Ruby 4.0.7, then frozen: parse 6, v4 4 and v7 6, uuid_v4 2 and uuid_v7
# 4, v1 9 and v6 9, v3 8 and v5 9, to_s and the comparisons 0, hex and
# urn 1, the v7 timestamp 2. A Symbol input costs what the String it
# carries costs — Symbol#name hands over a frozen String, no copy: parse
# 6, v3 7, v5 8.
describe "allocations" do
  # Objects allocated per run of the block, averaged over +times+ runs so a
  # one-off allocation outside the block (GC.stat's own, under coverage)
  # does not count.
  def allocations(times = 100, &block)
    before = GC.stat(:total_allocated_objects)
    times.times(&block)
    (GC.stat(:total_allocated_objects) - before) / times.to_f
  end

  it "parses in six objects" do
    string = "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
    Fast::UUID.parse(string)
    # The dehyphenated text, the packed bytes, the binary copy, the hex and
    # the canonical form.
    expect(allocations { Fast::UUID.parse(string) }).to be(:<, 7)
  end

  it "generates v4 in four objects" do
    Fast::UUID.v4
    # The random bytes, the binary copy, the hex and the value.
    expect(allocations { Fast::UUID.v4 }).to be(:<, 5)
  end

  it "generates v7 in six objects" do
    Fast::UUID.v7
    # v4's four, the now Time and the packed timestamp word.
    expect(allocations { Fast::UUID.v7 }).to be(:<, 7)
  end

  it "generates the uuid_v4 String in two objects" do
    Fast::UUID.uuid_v4
    # The random bytes and the hex; the value object is skipped.
    expect(allocations { Fast::UUID.uuid_v4 }).to be(:<, 3)
  end

  it "generates the uuid_v7 String in four objects" do
    Fast::UUID.uuid_v7
    # The random bytes, the now Time, the packed timestamp word and the
    # hex; the value object is skipped.
    expect(allocations { Fast::UUID.uuid_v7 }).to be(:<, 5)
  end

  it "generates v1 in at most thirteen objects" do
    # The now Time, the node's random bytes, the clock sequence's, the
    # composed timestamp word, the two words in their Array and the packed
    # bytes, then the value object's binary copy, hex and the value. v1's
    # time_low word crosses the immediate-Integer line whenever its top
    # bits are set — a phase that cycles with the clock every few minutes —
    # and 13 is that high phase; the low phase costs four fewer.
    Fast::UUID.v1
    expect(allocations { Fast::UUID.v1 }).to be(:<, 14)
  end

  it "generates v6 in at most nine objects" do
    # The same shape as v1: v6's field order changes the composition, not
    # the allocation, and v6's composed words stay inside the
    # immediate-Integers for the next few centuries.
    Fast::UUID.v6
    expect(allocations { Fast::UUID.v6 }).to be(:<, 10)
  end

  it "parses a Symbol in six objects" do
    symbol = :"017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
    Fast::UUID.parse(symbol)
    # The String budget's six, minus the #to_s copy: #name hands over the
    # frozen String the Symbol already carries.
    expect(allocations { Fast::UUID.parse(symbol) }).to be(:<, 7)
  end

  it "generates v3 in eight objects" do
    # The name's binary copy and the digest input it feeds, the MD5
    # machinery and its digest, then the value object's binary copy, hex
    # and the value.
    Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com")
    expect(allocations { Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, "www.example.com") }).to be(:<, 9)
  end

  it "generates v3 from a Symbol name in seven objects" do
    # The String name's seven: #name hands over the frozen String the
    # Symbol already carries, no #to_s copy.
    Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, :"www.example.com")
    expect(allocations { Fast::UUID.v3(Fast::UUID::NAMESPACE_DNS, :"www.example.com") }).to be(:<, 8)
  end

  it "generates v5 in nine objects" do
    # The same shape as v3, one object heavier: the 160-bit digest's
    # leftmost 128 bits are sliced out before they are stamped.
    Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com")
    expect(allocations { Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, "www.example.com") }).to be(:<, 10)
  end

  it "generates v5 from a Symbol name in eight objects" do
    # The same shape as v3's Symbol name, one object heavier: the 160-bit
    # digest's leftmost 128 bits are sliced out before they are stamped.
    Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, :"www.example.com")
    expect(allocations { Fast::UUID.v5(Fast::UUID::NAMESPACE_DNS, :"www.example.com") }).to be(:<, 9)
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
