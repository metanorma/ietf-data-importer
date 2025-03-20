# frozen_string_literal: true

require "lutaml/model"
require_relative "group"

module Ietf
  module Data
    module Importer
      # Represents a collection of IETF and IRTF groups
      class GroupCollection < Lutaml::Model::Serializable
        attribute :groups, Group, collection: true

        key_value do
          map "groups", to: :groups
        end
      end
    end
  end
end
