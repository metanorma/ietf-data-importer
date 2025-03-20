# frozen_string_literal: true

require "thor"
require "yaml"
require "fileutils"
require_relative "group_collection"
require_relative "scrapers"

module Ietf
  module Data
    module Importer
      # Command-line interface for IETF/IRTF group data
      class Cli < Thor
        desc "fetch OUTPUT_FILE", "Fetch IETF/IRTF groups and save to YAML file"
        option :format, type: :string, default: "yaml", desc: "Output format (yaml or json)"
        def fetch(output_file = nil)
          output_file ||= "ietf_groups.#{options[:format]}"

          # Fetch all groups using the scrapers
          collection = Ietf::Data::Importer::Scrapers.fetch_all

          # Save to file in the requested format
          format = options[:format].to_sym
          Ietf::Data::Importer::Scrapers.save_to_file(collection, output_file, format)
        end

        desc "integrate YAML_FILE", "Integrate YAML file as gem data"
        def integrate(yaml_file)
          # Validate YAML file
          begin
            collection = Ietf::Data::Importer::GroupCollection.from_yaml(File.read(yaml_file))
          rescue => e
            puts "Error reading YAML file: #{e.message}"
            exit 1
          end

          # Save as YAML for gem usage
          target_yaml = File.join(File.dirname(__FILE__), "groups.yaml")
          FileUtils.mkdir_p(File.dirname(target_yaml))
          File.write(target_yaml, File.read(yaml_file))

          puts "Integrated #{collection.groups.size} groups into gem"
        end
      end
    end
  end
end
