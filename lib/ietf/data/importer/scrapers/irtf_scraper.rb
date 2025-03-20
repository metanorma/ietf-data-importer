# frozen_string_literal: true

require_relative "base_scraper"
require_relative "../group_collection"

module Ietf
  module Data
    module Importer
      module Scrapers
        # Scraper for IRTF groups from irtf.org
        class IrtfScraper < BaseScraper
          # Base URL for IRTF website
          BASE_URL = "https://www.irtf.org/groups.html"

          # Fetch all IRTF groups
          # @return [Array<Ietf::Data::Importer::Group>] Array of Group objects
          def fetch
            groups = []
            log "Fetching IRTF groups..."

            begin
              doc = fetch_html(BASE_URL)
              return [] unless doc

              # First try to extract from the dropdown menu
              dropdown_groups = extract_from_dropdown(doc)
              if dropdown_groups.any?
                log "Found #{dropdown_groups.size} groups in dropdown menu", 1
                groups.concat(dropdown_groups)
                return groups
              end

              # If dropdown extraction fails, fall back to traditional section-based extraction
              # Debug the page structure
              headings = doc.css('h3').map(&:text).join(', ')
              log "Found headings on IRTF page: #{headings}", 1

              # Extract active groups
              active_groups = extract_groups(doc, 'Active Research Groups', 'active')
              log "Found #{active_groups.size} active IRTF groups", 1

              # Extract concluded groups
              concluded_groups = extract_groups(doc, 'Concluded Research Groups', 'concluded')
              log "Found #{concluded_groups.size} concluded IRTF groups", 1

              groups.concat(active_groups)
              groups.concat(concluded_groups)

              # If still no groups found, try alternative selectors
              if groups.empty?
                log "No groups found with standard selectors, trying alternatives...", 1

                # Try different section titles
                ['Current Research Groups', 'Research Groups', 'IRTF Groups'].each do |title|
                  section_groups = extract_groups(doc, title, 'active')
                  if section_groups.any?
                    log "Found #{section_groups.size} groups with section title: #{title}", 1
                    groups.concat(section_groups)
                  end
                end

                # Try a more generic approach if still no groups
                if groups.empty?
                  log "Using generic list item selector...", 1
                  # Find any unordered list with links
                  doc.css('ul').each do |list|
                    if list.css('li a').any?
                      generic_groups = extract_groups_from_list(list, 'active')
                      if generic_groups.any?
                        log "Found #{generic_groups.size} groups using generic list selector", 1
                        groups.concat(generic_groups)
                      end
                    end
                  end
                end
              end
            rescue => e
              log "Error fetching IRTF groups: #{e.message}", 1
            end

            groups
          end

          # Extract groups from the dropdown menu
          # @param doc [Nokogiri::HTML::Document] The HTML document
          # @return [Array<Ietf::Data::Importer::Group>] Array of Group objects
          def extract_from_dropdown(doc)
            groups = []

            # Look for the dropdown menu containing research groups
            dropdown = doc.css('a.dropdown-toggle').find do |el|
              el.text.include?('Research Groups')
            end

            return [] unless dropdown

            # Find the dropdown menu
            dropdown_parent = dropdown.parent
            dropdown_menu = dropdown_parent.css('.dropdown-menu')
            return [] unless dropdown_menu.any?

            log "Found dropdown menu with research groups", 1

            # Extract groups from the dropdown menu
            dropdown_menu.css('a.dropdown-item').each do |link|
              next unless link && link['href']

              name = link.text.strip
              href = link['href']

              # Extract abbreviation from href (e.g., cfrg.html -> CFRG)
              if href =~ /(\w+)\.html$/
                abbreviation = $1.upcase
              else
                next # Skip if we can't determine abbreviation
              end

              # Construct full URL if it's a relative path
              details_url = href
              if !details_url.start_with?('http')
                if details_url.start_with?('/')
                  details_url = "https://www.irtf.org#{details_url}"
                else
                  details_url = "https://www.irtf.org/#{details_url}"
                end
              end

              begin
                details = fetch_group_details(details_url)

                group = Importer::Group.new(
                  abbreviation: abbreviation,
                  name: name,
                  organization: 'irtf',
                  type: 'rg',
                  area: nil,
                  status: 'active', # Assume active since it's in the menu
                  description: nil, # Will be populated from details page if available
                  chairs: details[:chairs],
                  mailing_list: details[:mailing_list],
                  mailing_list_archive: details[:mailing_list_archive],
                  website_url: details_url,
                  charter_url: details[:charter_url],
                  concluded_date: details[:concluded_date]
                )

                groups << group
              rescue => e
                log "Error fetching details for #{abbreviation} (#{details_url}): #{e.message}", 2
              end
            end

            groups
          end

          private

          # Extract groups from a section on the IRTF page
          # @param doc [Nokogiri::HTML::Document] The HTML document
          # @param section_title [String] The title of the section to extract from
          # @param status [String] The status of the groups in this section (active/concluded)
          # @return [Array<Ietf::Data::Importer::Group>] Array of Group objects
          def extract_groups(doc, section_title, status)
            groups = []
            section = doc.xpath("//h3[contains(text(), '#{section_title}')]/following-sibling::ul[1]")

            section.css('li').each do |group_item|
              link = group_item.at_css('a')
              next unless link

              name = link.text.strip
              abbreviation = nil

              # Extract abbreviation from the text (typically in parentheses)
              if name =~ /\(([^)]+)\)/
                abbreviation = $1
              end

              # If unable to extract abbreviation, try from the URL
              if abbreviation.nil? && link['href'] =~ %r{/(\w+)/?$}
                abbreviation = $1.upcase
              end

              next unless abbreviation

              # Extract description (text after the link)
              description = group_item.text.sub(link.text, '').strip

              # Remove parenthesized abbreviation from description
              description = description.sub(/\s*\([^)]+\)\s*/, ' ').strip

              # Get details from the group's page
              details_url = link['href']
              begin
                details = fetch_group_details(details_url)

                group = Importer::Group.new(
                  abbreviation: abbreviation,
                  name: name.sub(/\s*\([^)]+\)\s*/, '').strip,
                  organization: 'irtf',
                  type: 'rg',
                  area: nil,
                  status: status,
                  description: description,
                  chairs: details[:chairs],
                  mailing_list: details[:mailing_list],
                  mailing_list_archive: details[:mailing_list_archive],
                  website_url: details_url,
                  charter_url: details[:charter_url],
                  concluded_date: details[:concluded_date]
                )

                groups << group
              rescue => e
                log "Error fetching details for #{abbreviation}: #{e.message}", 2
              end
            end

            groups
          end

          # Helper method to extract groups from any list without requiring a specific section heading
          # @param list_element [Nokogiri::XML::Element] The list element to extract from
          # @param status [String] The status of the groups in this list (active/concluded)
          # @return [Array<Ietf::Data::Importer::Group>] Array of Group objects
          def extract_groups_from_list(list_element, status)
            groups = []

            list_element.css('li').each do |group_item|
              link = group_item.at_css('a')
              next unless link && link['href']

              name = link.text.strip
              abbreviation = nil

              # Extract abbreviation from the text (typically in parentheses)
              if name =~ /\(([^)]+)\)/
                abbreviation = $1
              end

              # If unable to extract abbreviation, try from the URL
              if abbreviation.nil? && link['href'] =~ %r{/(\w+)/?$}
                abbreviation = $1.upcase
              end

              next unless abbreviation && !abbreviation.empty?

              # Extract description (text after the link)
              description = group_item.text.sub(link.text, '').strip

              # Remove parenthesized abbreviation from description
              description = description.sub(/\s*\([^)]+\)\s*/, ' ').strip

              # Get details from the group's page
              details_url = link['href']
              # Ensure we have a full URL
              if !details_url.start_with?('http')
                if details_url.start_with?('/')
                  details_url = "https://www.irtf.org#{details_url}"
                else
                  details_url = "https://www.irtf.org/#{details_url}"
                end
              end

              begin
                details = fetch_group_details(details_url)

                group = Importer::Group.new(
                  abbreviation: abbreviation,
                  name: name.sub(/\s*\([^)]+\)\s*/, '').strip,
                  organization: 'irtf',
                  type: 'rg',
                  area: nil,
                  status: status,
                  description: description,
                  chairs: details[:chairs],
                  mailing_list: details[:mailing_list],
                  mailing_list_archive: details[:mailing_list_archive],
                  website_url: details_url,
                  charter_url: details[:charter_url],
                  concluded_date: details[:concluded_date]
                )

                groups << group
              rescue => e
                log "Error fetching details for #{abbreviation} (#{details_url}): #{e.message}", 2
              end
            end

            groups
          end

          # Fetch details for a specific IRTF group from its page
          # @param url [String] The URL of the group's page
          # @return [Hash] Hash of group details
          def fetch_group_details(url)
            details = {
              chairs: [],
              mailing_list: nil,
              mailing_list_archive: nil,
              charter_url: nil,
              concluded_date: nil
            }

            doc = fetch_html(url)
            return details unless doc

            # Extract chairs
            chair_section = doc.xpath("//h3[contains(text(), 'Chair')]/following-sibling::p[1]")
            if chair_section
              details[:chairs] << chair_section.text.strip
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

            # Extract charter URL
            charter_link = doc.at_css('a[href*="charter"]')
            if charter_link
              details[:charter_url] = URI.join(url, charter_link['href']).to_s
            end

            # Extract concluded date from the page or the URL
            if url.include?('/concluded/')
              concluded_info = doc.text.match(/concluded in\s+([A-Z][a-z]+\s+\d{4})/)
              if concluded_info
                begin
                  details[:concluded_date] = Date.parse(concluded_info[1])
                rescue
                  # Just leave it as nil if we can't parse it
                end
              end
            end

            details
          end
        end
      end
    end
  end
end
