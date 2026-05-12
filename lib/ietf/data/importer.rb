# frozen_string_literal: true

require "yaml"

module Ietf
  module Data
    module Importer
      autoload :VERSION, "#{__dir__}/importer/version"
      autoload :Group, "#{__dir__}/importer/group"
      autoload :GroupCollection, "#{__dir__}/importer/group_collection"
      autoload :Cli, "#{__dir__}/importer/cli"
      autoload :Scrapers, "#{__dir__}/importer/scrapers"

      GROUPS_PATH = File.join(__dir__, "importer", "groups.yaml")

      class << self
        def collection
          @collection ||= GroupCollection.from_file(GROUPS_PATH)
        end

        def reset!
          @collection = nil
        end

        def load_groups
          collection
        end

        def groups
          collection.groups
        end

        def group_exists?(abbreviation)
          collection.exists?(abbreviation)
        end

        def find_group(abbreviation)
          collection.find_by_abbreviation(abbreviation)
        end

        def ietf_groups
          collection.ietf_groups
        end

        def irtf_groups
          collection.irtf_groups
        end

        def working_groups
          collection.working_groups
        end

        def research_groups
          collection.research_groups
        end

        def groups_by_type(type)
          collection.by_type(type)
        end

        def groups_by_area(area)
          collection.by_area(area)
        end

        def active_groups
          collection.active
        end

        def concluded_groups
          collection.concluded
        end

        def group_types
          collection.group_types
        end

        def areas
          collection.areas
        end
      end
    end
  end
end
