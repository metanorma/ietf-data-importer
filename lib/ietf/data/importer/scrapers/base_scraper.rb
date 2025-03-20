# frozen_string_literal: true

require "nokogiri"
require "open-uri"

module Ietf
  module Data
    module Importer
      module Scrapers
        # Base class for web scrapers
        class BaseScraper
          # Fetch HTML content from a URL and parse it with Nokogiri
          # @param url [String] The URL to fetch
          # @return [Nokogiri::HTML::Document] The parsed HTML document
          def fetch_html(url)
            Nokogiri::HTML(URI.open(url))
          rescue => e
            puts "  Error fetching URL #{url}: #{e.message}"
            nil
          end

          # Log a message with indentation
          # @param message [String] The message to log
          # @param level [Integer] The indentation level (default: 0)
          def log(message, level = 0)
            indent = "  " * level
            puts "#{indent}#{message}"
          end
        end
      end
    end
  end
end
