# frozen_string_literal: true

require_relative "scrapers/base_scraper"
require_relative "scrapers/ietf_scraper"
require_relative "scrapers/irtf_scraper"
require_relative "models"

module Metanorma
  module Ietf
    module Data
      # Module for IETF/IRTF web scrapers
      module Scrapers
        # Fetch all IETF and IRTF groups
        # @return [Metanorma::Ietf::Data::GroupCollection] Collection of all groups
        def self.fetch_all
          puts "Starting to fetch IETF and IRTF group data..."

          # Fetch IETF groups
          ietf_groups = IetfScraper.new.fetch
          puts "Fetched #{ietf_groups.size} IETF groups"

          # Fetch IRTF groups
          irtf_groups = IrtfScraper.new.fetch
          puts "Fetched #{irtf_groups.size} IRTF groups"

          # Combine all groups and return as a collection
          all_groups = ietf_groups + irtf_groups
          puts "Total: #{all_groups.size} groups"

          Data::GroupCollection.new(groups: all_groups)
        end

        # Fetch IETF groups only
        # @return [Array<Metanorma::Ietf::Data::Group>] Array of IETF groups
        def self.fetch_ietf
          IetfScraper.new.fetch
        end

        # Fetch IRTF groups only
        # @return [Array<Metanorma::Ietf::Data::Group>] Array of IRTF groups
        def self.fetch_irtf
          IrtfScraper.new.fetch
        end

        # Save group collection to a file
        # @param collection [Metanorma::Ietf::Data::GroupCollection] Group collection to save
        # @param file_path [String] Path to the output file
        # @param format [Symbol] Output format (:yaml or :json)
        def self.save_to_file(collection, file_path, format = :yaml)
          case format.to_sym
          when :yaml
            File.write(file_path, collection.to_yaml)
          when :json
            File.write(file_path, collection.to_json)
          else
            raise ArgumentError, "Unsupported format: #{format}"
          end

          puts "Saved #{collection.groups.size} groups to #{file_path}"
        end
      end
    end
  end
end
