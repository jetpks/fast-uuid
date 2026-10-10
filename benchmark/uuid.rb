# frozen_string_literal: true

# Generation and parsing against the references: securerandom for v4 and v7
# generation, uuidtools for parsing. benchmark-ips; quick mode with
# BENCH_QUICK=1.
#
#   bundle exec ruby benchmark/uuid.rb
#   BENCH_QUICK=1 bundle exec ruby benchmark/uuid.rb

require "securerandom"
require "uuidtools"
require "benchmark/ips"
require_relative "../lib/fast/uuid"

SAMPLE = "017F22E2-79B0-7CC3-98C4-DC0C0C07398F"
QUICK = ENV["BENCH_QUICK"]

# One settled call's object count, GC off over the timed batch.
def objects_per_call(call, times = 10_000)
  call.call
  GC.start
  GC.disable
  before = GC.stat(:total_allocated_objects)
  times.times { call.call }
  (GC.stat(:total_allocated_objects) - before) / times.to_f
ensure
  GC.enable
end

operations = {
  "generate v4, fast-uuid" => -> { Fast::UUID.v4 },
  "generate v4, securerandom" => -> { SecureRandom.uuid_v4 },
  "generate v7, fast-uuid" => -> { Fast::UUID.v7 },
  "generate v7, securerandom" => -> { SecureRandom.uuid_v7 },
  "uuid_v4 string, fast-uuid" => -> { Fast::UUID.uuid_v4 },
  "uuid_v7 string, fast-uuid" => -> { Fast::UUID.uuid_v7 },
  "parse, fast-uuid" => -> { Fast::UUID.parse(SAMPLE) },
  "parse, uuidtools" => -> { UUIDTools::UUID.parse(SAMPLE) }
}

puts "#{RUBY_DESCRIPTION}; fast-uuid #{Fast::UUID::VERSION}"

report = Benchmark.ips do |x|
  x.quiet = true
  x.config(time: QUICK ? 0.5 : 2, warmup: QUICK ? 0.2 : 0.5)
  operations.each { |name, call| x.report(name, &call) }
end

width = operations.keys.map(&:length).max
report.entries.each do |entry|
  call = operations.fetch(entry.label)
  objects = objects_per_call(call)
  puts format("%<label>-#{width}s %<ips>10.0f i/s ±%<stddev>5.2f%% (%<objects>6.2f objects/call)",
              label: entry.label, ips: entry.ips, stddev: entry.stats.error / entry.ips * 100, objects: objects)
end
