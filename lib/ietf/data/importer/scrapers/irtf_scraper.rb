# frozen_string_literal: true

require_relative "base_scraper"

module Ietf
  module Data
    module Importer
      module Scrapers
        class IrtfScraper < BaseScraper
          BASE_URL = "https://www.irtf.org/groups.html"

          SECTION_TITLES = [
            "Active Research Groups",
            "Current Research Groups",
            "Research Groups",
            "IRTF Groups",
          ].freeze

          def fetch
            log "Fetching IRTF groups..."

            doc = fetch_html(BASE_URL)
            return build_collection([]) unless doc

            groups = extract_from_dropdown(doc)
            return build_collection(groups) if groups.any?

            log "Dropdown extraction empty, falling back to section parsing", 1
            build_collection(extract_from_sections(doc))
          rescue StandardError => e
            log "Error fetching IRTF groups: #{e.message}", 1
            build_collection([])
          end

          private

          def extract_from_dropdown(doc)
            dropdown = doc.css("a.dropdown-toggle").find do |el|
              el.text.include?("Research Groups")
            end
            return [] unless dropdown

            menu = dropdown.parent.css(".dropdown-menu")
            return [] unless menu.any?

            log "Found dropdown menu with research groups", 1

            menu.css("a.dropdown-item").filter_map do |link|
              next unless link && link["href"]

              abbreviation = extract_abbreviation_from_href(link["href"])
              next unless abbreviation

              details_url = resolve_url(link["href"])
              details = fetch_group_details(details_url)

              build_group(
                abbreviation: abbreviation,
                name: link.text.strip,
                organization: "irtf",
                type: "rg",
                status: "active",
                website_url: details_url,
                **details,
              )
            rescue StandardError => e
              log "Error fetching details for #{abbreviation} (#{details_url}): #{e.message}",
                  2
              nil
            end
          end

          def extract_from_sections(doc)
            log "Found headings: #{doc.css('h3').map(&:text).join(', ')}", 1

            active = extract_from_section(doc, "Active Research Groups",
                                          "active")
            log "Found #{active.size} active IRTF groups", 1

            concluded = extract_from_section(doc, "Concluded Research Groups",
                                             "concluded")
            log "Found #{concluded.size} concluded IRTF groups", 1

            groups = active + concluded
            return groups if groups.any?

            log "No groups found with standard selectors, trying alternatives...",
                1
            extract_from_fallback_sections(doc)
          end

          def extract_from_section(doc, title, status)
            section = doc.xpath("//h3[contains(text(), '#{title}')]/following-sibling::ul[1]")
            extract_groups_from_list(section, status)
          end

          def extract_from_fallback_sections(doc)
            SECTION_TITLES.each do |title|
              groups = extract_from_section(doc, title, "active")
              return groups if groups.any?
            end

            doc.css("ul").flat_map do |list|
              next [] unless list.css("li a").any?

              extract_groups_from_list(list, "active")
            end
          end

          def extract_groups_from_list(list_element, status)
            list_element.css("li").filter_map do |item|
              link = item.at_css("a")
              next unless link && link["href"]

              name = link.text.strip
              abbreviation = extract_abbreviation(name, link["href"])
              next unless abbreviation

              description = extract_description(item, link)
              details_url = resolve_url(link["href"])
              details = fetch_group_details(details_url)

              build_group(
                abbreviation: abbreviation,
                name: name.sub(/\s*\([^)]+\)\s*/, "").strip,
                organization: "irtf",
                type: "rg",
                status: status,
                description: description,
                website_url: details_url,
                **details,
              )
            rescue StandardError => e
              log "Error fetching details for #{abbreviation} (#{details_url}): #{e.message}",
                  2
              nil
            end
          end

          def extract_abbreviation(name, href)
            if name =~ /\(([^)]+)\)/
              $1
            elsif href =~ %r{/(\w+)/?$}
              $1.upcase
            end
          end

          def extract_abbreviation_from_href(href)
            $1.upcase if href =~ /(\w+)\.html$/
          end

          def extract_description(item, link)
            item.text.sub(link.text, "").sub(/\s*\([^)]+\)\s*/, " ").strip
          end

          def resolve_url(href)
            case href
            when %r{\Ahttps?://} then href
            when %r{\A/} then "https://www.irtf.org#{href}"
            else "https://www.irtf.org/#{href}"
            end
          end

          def fetch_group_details(url)
            doc = fetch_html(url)
            return {} unless doc

            {
              chairs: extract_chairs(doc),
              mailing_list: doc.at_css('a[href^="mailto:"]')&.[]("href")&.sub(
                "mailto:", ""
              ),
              mailing_list_archive: doc.at_css('a[href*="mailarchive.ietf.org"]')&.[]("href"),
              charter_url: extract_charter_url(doc, url),
              concluded_date: extract_concluded_date(doc, url),
            }
          end

          def extract_chairs(doc)
            chair = doc.xpath("//h3[contains(text(), 'Chair')]/following-sibling::p[1]")
            chair ? [chair.text.strip] : []
          end

          def extract_charter_url(doc, base_url)
            link = doc.at_css('a[href*="charter"]')
            URI.join(base_url, link["href"]).to_s if link
          end

          def extract_concluded_date(doc, url)
            return nil unless url.include?("/concluded/")

            match = doc.text.match(/concluded in\s+([A-Z][a-z]+\s+\d{4})/)
            Date.parse(match[1]) if match
          rescue Date::Error
            nil
          end
        end
      end
    end
  end
end
