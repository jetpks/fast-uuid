# frozen_string_literal: true

require_relative "lib/fast/uuid/version"

Gem::Specification.new do |spec|
  spec.name = "fast-uuid"
  spec.version = Fast::UUID::VERSION

  spec.summary = "RFC 9562 UUIDs for Ruby: generate v4/v7, parse every version, compare, no dependencies."
  spec.authors = ["Eric Jacobs"]
  spec.license = "MIT"

  spec.homepage = "https://github.com/jetpks/fast-uuid"

  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jetpks/fast-uuid"
  spec.metadata["changelog_uri"] = "https://github.com/jetpks/fast-uuid/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
end
