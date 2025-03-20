# frozen_string_literal: true

require_relative "data/version"
require_relative "data/models"
require_relative "data/groups"
require_relative "data/scrapers"

module Metanorma
  module Ietf
    # Main module for IETF/IRTF group data
    module Data
      class Error < StandardError; end

      # All methods are defined in the groups.rb file
    end
  end
end
