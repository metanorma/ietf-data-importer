# frozen_string_literal: true

require_relative "scrapers/base_scraper"
require_relative "scrapers/ietf_scraper"
require_relative "scrapers/irtf_scraper"

module Ietf
  module Data
    module Importer
      module Scrapers
        def self.fetch_all
          puts "Starting to fetch IETF and IRTF group data..."

          ietf = fetch_ietf
          puts "Fetched #{ietf.size} IETF groups"

          irtf = fetch_irtf
          puts "Fetched #{irtf.size} IRTF groups"

          merged = ietf.merge(irtf)
          puts "Total: #{merged.size} groups"

          merged
        end

        def self.fetch_ietf
          IetfScraper.new.fetch
        end

        def self.fetch_irtf
          IrtfScraper.new.fetch
        end
      end
    end
  end
end
