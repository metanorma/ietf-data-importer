# frozen_string_literal: true

require "yaml"
require_relative "importer/version"
require_relative "importer/group_collection"
require_relative "importer/scrapers"
require_relative "importer/cli"

module Ietf
  module Data
    # Main module for IETF/IRTF group data importer
    module Importer
      class Error < StandardError; end

      # Path to the groups data file
      GROUPS_PATH = File.join(File.dirname(__FILE__), "importer", "groups.yaml")

      # Load the groups if the file exists, otherwise return empty collection
      def self.load_groups
        if File.exist?(GROUPS_PATH)
          GroupCollection.from_yaml(File.read(GROUPS_PATH))
        else
          GroupCollection.new(groups: [])
        end
      end

      # All available groups
      def self.groups
        load_groups.groups
      end

      # Check if a group exists by abbreviation
      def self.group_exists?(abbreviation)
        !find_group(abbreviation).nil?
      end

      # Find a group by its abbreviation (case insensitive)
      def self.find_group(abbreviation)
        groups.find { |g| g.abbreviation.downcase == abbreviation.to_s.downcase }
      end

      # Get all IETF groups
      def self.ietf_groups
        groups.select { |g| g.organization == "ietf" }
      end

      # Get all IRTF groups
      def self.irtf_groups
        groups.select { |g| g.organization == "irtf" }
      end

      # Get all working groups (IETF)
      def self.working_groups
        groups.select { |g| g.type == "wg" }
      end

      # Get all research groups (IRTF)
      def self.research_groups
        groups.select { |g| g.type == "rg" }
      end

      # Get groups by type
      def self.groups_by_type(type)
        groups.select { |g| g.type.downcase == type.to_s.downcase }
      end

      # Get groups by area
      def self.groups_by_area(area)
        groups.select { |g| g.area&.downcase == area.to_s.downcase }
      end

      # Get active groups
      def self.active_groups
        groups.select { |g| g.status == "active" }
      end

      # Get concluded groups
      def self.concluded_groups
        groups.select { |g| g.status == "concluded" }
      end

      # Get all available group types
      def self.group_types
        groups.map(&:type).uniq.sort
      end

      # Get all available areas
      def self.areas
        groups.map(&:area).compact.uniq.sort
      end
    end
  end
end
