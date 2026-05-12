# frozen_string_literal: true

require "nokogiri"
require "open-uri"
require_relative "../group"
require_relative "../group_collection"

module Ietf
  module Data
    module Importer
      module Scrapers
        class BaseScraper
          def fetch
            raise NotImplementedError, "#{self.class}#fetch must be implemented"
          end

          def fetch_html(url)
            Nokogiri::HTML(URI.open(url))
          rescue StandardError => e
            log "Error fetching URL #{url}: #{e.message}"
            nil
          end

          def log(message, level = 0)
            indent = "  " * level
            puts "#{indent}#{message}"
          end

          private

          def build_group(attributes)
            Group.new(attributes)
          end

          def build_collection(groups)
            GroupCollection.new(groups: groups)
          end
        end
      end
    end
  end
end
