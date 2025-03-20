# frozen_string_literal: true

require_relative "base_scraper"
require_relative "../group_collection"

module Ietf
  module Data
    module Importer
      module Scrapers
        # Scraper for IETF groups from datatracker.ietf.org
        class IetfScraper < BaseScraper
          # Base URL for IETF datatracker
          BASE_URL = "https://datatracker.ietf.org/group/"

          # Fetch all IETF groups
          # @return [Array<Ietf::Data::Importer::Group>] Array of Group objects
          def fetch
            groups = []
            log "Fetching IETF groups..."

            # Fetch all group types
            group_types = fetch_group_types

            # For each group type, fetch its groups
            group_types.each do |type|
              log "Fetching #{type[:name]} groups...", 1

              # Skip if URL is empty
              next if type[:url].nil? || type[:url].empty?

              # Construct the full URL
              type_url = if type[:url].start_with?('/')
                "https://datatracker.ietf.org#{type[:url]}"
              else
                "https://datatracker.ietf.org/#{type[:url]}"
              end
              type_doc = fetch_html(type_url)
              next unless type_doc

              # Extract groups from the table
              extract_groups_from_table(type_doc, type, groups)
            end

            groups
          end

          private

          # Fetch all group types from the main IETF groups page
          # @return [Array<Hash>] Array of group type information
          def fetch_group_types
            doc = fetch_html(BASE_URL)
            return [] unless doc

            log "Looking for group types on the page...", 1

            # Extract group types from the table on the main page
            group_types = []

            # Try to find from the table first
            doc.css('table.tablesorter tbody tr').each do |row|
              type_cell = row.at_css('td a')
              next unless type_cell && type_cell['href']

              href = type_cell['href']
              next unless href.include?('/')

              type_abbr = href.sub(/\/$/, '').split('/').last
              name = type_cell.text.strip

              group_types << {
                name: name,
                abbreviation: type_abbr.downcase,
                url: href
              }
            end

            # If we didn't find any types in the table, use the predefined list
            if group_types.empty?
              log "Using predefined group types...", 1
              standard_types = [
                { name: "Working Group", abbreviation: "wg", url: "/wg/" },
                { name: "Research Group", abbreviation: "rg", url: "/rg/" },
                { name: "Area", abbreviation: "area", url: "/area/" },
                { name: "Team", abbreviation: "team", url: "/team/" },
                { name: "Program", abbreviation: "program", url: "/program/" },
                { name: "Directorate", abbreviation: "dir", url: "/dir/" },
                { name: "Advisory Group", abbreviation: "ag", url: "/ag/" },
                { name: "BOF", abbreviation: "bof", url: "/bof/" }
              ]
              group_types = standard_types
            end

            log "Found #{group_types.size} group types: #{group_types.map { |t| t[:abbreviation] }.join(', ')}", 1
            group_types
          end

          # Extract groups from a table on the group type page
          # @param doc [Nokogiri::HTML::Document] The HTML document
          # @param type [Hash] The group type information
          # @param groups [Array<Ietf::Data::Importer::Group>] Array to add groups to
          def extract_groups_from_table(doc, type, groups)
            # Try different table selectors
            selectors = [
              '.group-list tbody tr',            # Traditional format
              'table.table-sm tbody tr',         # New table format
              'table.tablesorter tbody tr'       # Another possible format
            ]

            rows = []
            selectors.each do |selector|
              found_rows = doc.css(selector)
              if found_rows.any?
                log "Found #{found_rows.size} groups using selector: #{selector}", 2
                rows = found_rows
                break
              end
            end

            rows.each do |row|
              # Try different selectors for finding the abbreviation and name
              abbreviation = nil
              name = nil

              # First, try to find the abbreviation and name using standard classes
              abbreviation ||= row.at_css('.acronym')&.text&.strip
              name ||= row.at_css('.name')&.text&.strip

              # If that doesn't work, try to find by column position
              if abbreviation.nil? || name.nil?
                # First column might be the abbreviation, second might be the name
                cells = row.css('td')
                if cells.size >= 2
                  abbreviation ||= cells[0].text.strip
                  name ||= cells[1].text.strip
                end
              end

              # If we still don't have them, try to extract from links
              if abbreviation.nil? || name.nil?
                link = row.at_css('a')
                if link
                  # Try to extract abbreviation from the URL
                  if link['href'] =~ %r{/([^/]+)/?$}
                    abbreviation ||= $1.upcase
                  end

                  # Use link text as the name
                  name ||= link.text.strip
                end
              end

              # Skip if we still couldn't extract basic info
              next unless abbreviation && name && !abbreviation.empty? && !name.empty?

              # Extract other fields from the row
              status = 'active'  # Default to active

              # Try to find status from row classes or content
              status = 'concluded' if row['class'] && row['class'].include?('concluded')
              status = 'concluded' if row.text.include?('Concluded')
              status = 'active' if row.at_css('.active') || row.text.include?('Active')

              # Try to find the area
              area = nil
              area_element = row.at_css('.area')
              area = area_element.text.strip if area_element

              # Get the group detail page URL
              detail_link = row.at_css('a')
              next unless detail_link

              group_url = detail_link['href']
              detail_url = URI.join(BASE_URL, group_url)

              # Fetch additional details from the group's page
              begin
                details = fetch_group_details(detail_url)

                # Create Group object
                group = Importer::Group.new(
                  abbreviation: abbreviation,
                  name: name,
                  organization: 'ietf',
                  type: type[:abbreviation],
                  area: area,
                  status: status,
                  description: details[:description],
                  chairs: details[:chairs],
                  mailing_list: details[:mailing_list],
                  mailing_list_archive: details[:mailing_list_archive],
                  website_url: details[:website_url],
                  charter_url: details[:charter_url],
                  concluded_date: details[:concluded_date]
                )

                groups << group
              rescue => e
                log "Error fetching details for #{abbreviation}: #{e.message}", 2
              end
            end
          end

          # Fetch details for a specific group from its page
          # @param url [String] The URL of the group's page
          # @return [Hash] Hash of group details
          def fetch_group_details(url)
            details = {
              description: nil,
              chairs: [],
              mailing_list: nil,
              mailing_list_archive: nil,
              website_url: nil,
              charter_url: nil,
              concluded_date: nil
            }

            doc = fetch_html(url)
            return details unless doc

            # Extract description from charter
            charter_section = doc.at_css('#charter')
            if charter_section
              details[:description] = charter_section.text.strip
            end

            # Extract chairs
            doc.css('.role-WG-chair, .role-RG-chair').each do |chair|
              details[:chairs] << chair.text.strip
            end

            # Extract mailing list
            mailing_list = doc.at_css('a[href^="mailto:"]')
            if mailing_list
              details[:mailing_list] = mailing_list['href'].sub('mailto:', '')
            end

            # Extract mailing list archive
            archive = doc.at_css('a[href*="mailarchive.ietf.org"]')
            if archive
              details[:mailing_list_archive] = archive['href']
            end

            # Extract website if available
            website = doc.at_css('.additional-urls a')
            if website
              details[:website_url] = website['href']
            end

            # Extract charter URL
            charter_link = doc.at_css('a[href*="/charter/"]')
            if charter_link
              details[:charter_url] = URI.join("https://datatracker.ietf.org", charter_link['href']).to_s
            end

            # Extract concluded date
            concluded_info = doc.text.match(/Concluded\s+([A-Z][a-z]+\s+\d{4})/)
            if concluded_info
              begin
                details[:concluded_date] = Date.parse(concluded_info[1])
              rescue
                # Just leave it as nil if we can't parse it
              end
            end

            details
          end
        end
      end
    end
  end
end
