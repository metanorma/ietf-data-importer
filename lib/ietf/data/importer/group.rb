# frozen_string_literal: true

require "lutaml/model"

module Ietf
  module Data
    module Importer
      class Group < Lutaml::Model::Serializable
        ORGANIZATIONS = %w[ietf irtf].freeze
        STATUSES = %w[active concluded bof proposed].freeze
        TYPES = %w[wg rg area team program dir ag bof].freeze

        attribute :abbreviation, :string
        attribute :name, :string
        attribute :organization, :string
        attribute :type, :string
        attribute :area, :string
        attribute :status, :string
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

        def active?
          status == "active"
        end

        def concluded?
          status == "concluded"
        end

        def bof?
          status == "bof"
        end

        def proposed?
          status == "proposed"
        end

        def ietf?
          organization == "ietf"
        end

        def irtf?
          organization == "irtf"
        end

        def working_group?
          type == "wg"
        end

        def research_group?
          type == "rg"
        end
      end
    end
  end
end
