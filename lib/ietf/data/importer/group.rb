# frozen_string_literal: true

require "lutaml/model"

module Ietf
  module Data
    module Importer
      # Represents a single IETF or IRTF group
      class Group < Lutaml::Model::Serializable
        attribute :abbreviation, :string
        attribute :name, :string
        attribute :organization, :string  # 'ietf' or 'irtf'
        attribute :type, :string  # 'wg', 'rg', etc.
        attribute :area, :string
        attribute :status, :string, values: %w[active concluded bof proposed]
        attribute :description, :string
        attribute :chairs, :string, collection: true
        attribute :mailing_list, :string
        attribute :mailing_list_archive, :string
        attribute :website_url, :string
        attribute :charter_url, :string
        attribute :concluded_date, :date

        key_value do
          map "abbreviation", to: :abbreviation
          map "name", to: :name
          map "organization", to: :organization
          map "type", to: :type
          map "area", to: :area
          map "status", to: :status
          map "description", to: :description
          map "chairs", to: :chairs
          map "mailing_list", to: :mailing_list
          map "mailing_list_archive", to: :mailing_list_archive
          map "website_url", to: :website_url
          map "charter_url", to: :charter_url
          map "concluded_date", to: :concluded_date
        end
      end
    end
  end
end
