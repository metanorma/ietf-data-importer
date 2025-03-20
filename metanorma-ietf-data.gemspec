# frozen_string_literal: true

require_relative "lib/metanorma/ietf/data/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-ietf-data"
  spec.version       = Metanorma::Ietf::Data::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary = <<~SUMMARY
    metanorma-ietf-data contains IETF working and IRTF research groups
  SUMMARY
  spec.description = <<~DESCRIPTION
    this make sens because https://tools.ietf.org/wg/
    and https://irtf.org/groups often unavailable
  DESCRIPTION
  spec.homepage      = "https://github.com/metanorma/metanorma-ietf"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.add_dependency "lutaml-model", "~> 0.1"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "nokogiri", "~> 1.12"
  spec.add_dependency "yaml", "~> 0.2"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
