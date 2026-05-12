# frozen_string_literal: true

require "thor"
require "fileutils"

module Ietf
  module Data
    module Importer
      class Cli < Thor
        desc "fetch OUTPUT_FILE", "Fetch IETF/IRTF groups and save to file"
        option :format, type: :string, default: "yaml",
                        desc: "Output format (yaml or json)"
        def fetch(output_file = nil)
          output_file ||= "ietf_groups.#{options[:format]}"

          collection = Scrapers.fetch_all
          collection.save(output_file, format: options[:format].to_sym)

          puts "Saved #{collection.size} groups to #{output_file}"
        end

        desc "integrate YAML_FILE", "Integrate YAML file as gem data"
        def integrate(yaml_file)
          collection = GroupCollection.from_yaml(File.read(yaml_file))

          target = File.join(__dir__, "groups.yaml")
          FileUtils.mkdir_p(File.dirname(target))
          File.write(target, File.read(yaml_file))

          puts "Integrated #{collection.size} groups into gem"
        rescue StandardError => e
          puts "Error reading YAML file: #{e.message}"
          exit 1
        end
      end
    end
  end
end
