# frozen_string_literal: true

require_relative "lib/ietf/data/importer/version"

Gem::Specification.new do |spec|
  spec.name          = "ietf-data-importer"
  spec.version       = Ietf::Data::Importer::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary = <<~SUMMARY
    Offline access to IETF working groups and IRTF research groups metadata
  SUMMARY
  spec.description = <<~DESCRIPTION
    ietf-data-importer offers reliable offline access to metadata for IETF working groups
    and IRTF research groups. This provides a dependable alternative to the official
    resources at https://tools.ietf.org/wg/ and https://irtf.org/groups, which may
    experience downtime or connectivity issues.
  DESCRIPTION
  spec.homepage      = "https://github.com/metanorma/ietf-data-importer"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.add_dependency "lutaml-model", "~> 0.7"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "nokogiri", "~> 1.18"
  spec.add_dependency "yaml"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
