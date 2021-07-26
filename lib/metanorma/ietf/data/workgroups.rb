# frozen_string_literal: true

module Metanorma
  module Ietf
    module Data
      WORKGROUPS = File.read(
        File.join(File.dirname(__FILE__), "workgroups.json"),
      ).to_json
    end
  end
end
