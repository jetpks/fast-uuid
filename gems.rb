# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :test do
  gem "sus"
  gem "covered"
  gem "rubocop"
  # The reference parser the benchmark compares against. Never a runtime
  # dependency.
  gem "uuidtools"
end

group :benchmark do
  gem "benchmark-ips"
end
