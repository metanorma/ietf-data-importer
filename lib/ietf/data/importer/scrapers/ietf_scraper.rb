# frozen_string_literal: true

require_relative "base_scraper"

module Ietf
  module Data
    module Importer
      module Scrapers
        class IetfScraper < BaseScraper
          BASE_URL = "https://datatracker.ietf.org/group/"

          STANDARD_TYPES = [
            { name: "Working Group", abbreviation: "wg", url: "/wg/" },
            { name: "Research Group", abbreviation: "rg", url: "/rg/" },
            { name: "Area", abbreviation: "area", url: "/area/" },
            { name: "Team", abbreviation: "team", url: "/team/" },
            { name: "Program", abbreviation: "program", url: "/program/" },
            { name: "Directorate", abbreviation: "dir", url: "/dir/" },
            { name: "Advisory Group", abbreviation: "ag", url: "/ag/" },
            { name: "BOF", abbreviation: "bof", url: "/bof/" },
          ].freeze

          TABLE_SELECTORS = [
            ".group-list tbody tr",
            "table.table-sm tbody tr",
            "table.tablesorter tbody tr",
          ].freeze

          def fetch
            log "Fetching IETF groups..."

            group_types = fetch_group_types

            groups = group_types.flat_map do |type|
              log "Fetching #{type[:name]} groups...", 1
              next [] if type[:url].nil? || type[:url].empty?

              type_url = resolve_url(type[:url])
              type_doc = fetch_html(type_url)
              next [] unless type_doc

              extract_groups_from_table(type_doc, type)
            end

            build_collection(groups)
          end

          private

          def resolve_url(path)
            if path.start_with?("/")
              "https://datatracker.ietf.org#{path}"
            else
              "https://datatracker.ietf.org/#{path}"
            end
          end

          def fetch_group_types
            doc = fetch_html(BASE_URL)
            return STANDARD_TYPES unless doc

            log "Looking for group types on the page...", 1

            discovered = discover_group_types(doc)
            if discovered.empty?
              log "Using predefined group types...", 1
              STANDARD_TYPES
            else
              log "Found #{discovered.size} group types: #{discovered.map do |t|
                t[:abbreviation]
              end.join(', ')}", 1
              discovered
            end
          end

          def discover_group_types(doc)
            doc.css("table.tablesorter tbody tr").filter_map do |row|
              type_cell = row.at_css("td a")
              next unless type_cell && type_cell["href"]

              href = type_cell["href"]
              next unless href.include?("/")

              {
                name: type_cell.text.strip,
                abbreviation: href.sub(%r{/$}, "").split("/").last.downcase,
                url: href,
              }
            end
          end

          def extract_groups_from_table(doc, type)
            rows = TABLE_SELECTORS.filter_map do |selector|
              found = doc.css(selector)
              found.any? ? found : nil
            end.first || []

            rows.filter_map do |row|
              extract_group_from_row(row, type)
            end
          end

          def extract_group_from_row(row, type)
            basic = extract_basic_info(row)
            return nil unless basic[:abbreviation] && basic[:name]

            status = determine_status(row)
            area = row.at_css(".area")&.text&.strip

            detail_link = row.at_css("a")
            return nil unless detail_link

            detail_url = URI.join(BASE_URL, detail_link["href"])
            details = fetch_group_details(detail_url)

            build_group(
              abbreviation: basic[:abbreviation],
              name: basic[:name],
              organization: "ietf",
              type: type[:abbreviation],
              area: area,
              status: status,
              **details,
            )
          rescue StandardError => e
            log "Error fetching details for #{basic&.dig(:abbreviation)}: #{e.message}",
                2
            nil
          end

          def extract_basic_info(row)
            abbreviation = row.at_css(".acronym")&.text&.strip
            name = row.at_css(".name")&.text&.strip

            if abbreviation.nil? || name.nil?
              cells = row.css("td")
              if cells.size >= 2
                abbreviation ||= cells[0].text.strip
                name ||= cells[1].text.strip
              end
            end

            if abbreviation.nil? || name.nil?
              link = row.at_css("a")
              if link
                abbreviation ||= $1.upcase if link["href"] =~ %r{/([^/]+)/?$}
                name ||= link.text.strip
              end
            end

            { abbreviation: abbreviation, name: name }
          end

          def determine_status(row)
            return "concluded" if row["class"]&.include?("concluded")
            return "concluded" if row.text.include?("Concluded")
            return "active" if row.at_css(".active") || row.text.include?("Active")

            "active"
          end

          def fetch_group_details(url)
            doc = fetch_html(url)
            return {} unless doc

            {
              description: doc.at_css("#charter")&.text&.strip,
              chairs: doc.css(".role-WG-chair, .role-RG-chair").map do |c|
                c.text.strip
              end,
              mailing_list: doc.at_css('a[href^="mailto:"]')&.[]("href")&.sub(
                "mailto:", ""
              ),
              mailing_list_archive: doc.at_css('a[href*="mailarchive.ietf.org"]')&.[]("href"),
              website_url: doc.at_css(".additional-urls a")&.[]("href"),
              charter_url: extract_charter_url(doc),
              concluded_date: extract_concluded_date(doc),
            }
          end

          def extract_charter_url(doc)
            link = doc.at_css('a[href*="/charter/"]')
            URI.join("https://datatracker.ietf.org", link["href"]).to_s if link
          end

          def extract_concluded_date(doc)
            match = doc.text.match(/Concluded\s+([A-Z][a-z]+\s+\d{4})/)
            Date.parse(match[1]) if match
          rescue Date::Error
            nil
          end
        end
      end
    end
  end
end
