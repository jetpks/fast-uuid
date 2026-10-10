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

# Each fast-uuid operation beside the call it replaces: the String drop-ins
# first, then the value objects, then parsing.
operations = {
  "Fast::UUID.uuid_v4 => String" => -> { Fast::UUID.uuid_v4 },
  "SecureRandom.uuid_v4 => String" => -> { SecureRandom.uuid_v4 },
  "Fast::UUID.uuid_v7 => String" => -> { Fast::UUID.uuid_v7 },
  "SecureRandom.uuid_v7 => String" => -> { SecureRandom.uuid_v7 },
  "Fast::UUID.v7 => Fast::UUID" => -> { Fast::UUID.v7 },
  "Fast::UUID.v4 => Fast::UUID" => -> { Fast::UUID.v4 },
  "Fast::UUID.parse" => -> { Fast::UUID.parse(SAMPLE) },
  "UUIDTools::UUID.parse" => -> { UUIDTools::UUID.parse(SAMPLE) }
}

puts "#{RUBY_DESCRIPTION}; fast-uuid #{Fast::UUID::VERSION}"

report = Benchmark.ips do |x|
  x.quiet = true
  x.config(time: QUICK ? 0.5 : 5, warmup: QUICK ? 0.2 : 1)
  operations.each { |name, call| x.report(name, &call) }
end

# The doc's results table: operation, comma-grouped i/s, ±% and objects/call.
def grouped(number)
  number.round.to_s.gsub(/(\d)(?=(\d{3})+\z)/, "\\1,")
end

puts "| operation | i/s | ±% | objects/call |"
puts "|---|---|---|---|"
report.entries.each do |entry|
  objects = objects_per_call(operations.fetch(entry.label))
  error = entry.stats.error / entry.ips * 100
  puts format("| %<label>s | %<ips>s | %<error>.2f | %<objects>.2f |",
              label: entry.label, ips: grouped(entry.ips), error: error, objects: objects)
end
