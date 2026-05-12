# frozen_string_literal: true

require "lutaml/model"
require_relative "group"

module Ietf
  module Data
    module Importer
      class GroupCollection < Lutaml::Model::Serializable
        include Enumerable

        attribute :groups, Group, collection: true

        key_value do
          map "groups", to: :groups
        end

        def each(&block)
          groups.each(&block)
        end

        def size
          groups.size
        end

        def empty?
          groups.empty?
        end

        def [](abbreviation)
          find_by_abbreviation(abbreviation)
        end

        def find_by_abbreviation(abbreviation)
          groups.find do |g|
            g.abbreviation.downcase == abbreviation.to_s.downcase
          end
        end

        def exists?(abbreviation)
          !find_by_abbreviation(abbreviation).nil?
        end

        def by_organization(org)
          self.class.new(groups: groups.select do |g|
            g.organization == org.to_s
          end)
        end

        def by_type(type)
          self.class.new(groups: groups.select do |g|
            g.type&.downcase == type.to_s.downcase
          end)
        end

        def by_area(area)
          self.class.new(groups: groups.select do |g|
            g.area&.downcase == area.to_s.downcase
          end)
        end

        def active
          self.class.new(groups: groups.select(&:active?))
        end

        def concluded
          self.class.new(groups: groups.select(&:concluded?))
        end

        def working_groups
          by_type("wg")
        end

        def research_groups
          by_type("rg")
        end

        def ietf_groups
          by_organization("ietf")
        end

        def irtf_groups
          by_organization("irtf")
        end

        def group_types
          groups.filter_map(&:type).uniq.sort
        end

        def areas
          groups.filter_map(&:area).uniq.sort
        end

        def merge(other)
          self.class.new(groups: groups + other.groups)
        end

        def self.from_file(path, format: :yaml)
          return new(groups: []) unless File.exist?(path)

          content = File.read(path)
          case format
          when :yaml then from_yaml(content)
          when :json then from_json(content)
          else raise ArgumentError, "Unsupported format: #{format}"
          end
        end

        def save(path, format: :yaml)
          case format
          when :yaml then File.write(path, to_yaml)
          when :json then File.write(path, to_json)
          else raise ArgumentError, "Unsupported format: #{format}"
          end
        end
      end
    end
  end
end
