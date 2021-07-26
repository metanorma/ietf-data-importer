# frozen_string_literal: true

require "json"
require "metanorma/ietf/data/workgroups"

RSpec.describe Metanorma::Ietf::Data do
  it "has a version number" do
    expect(Metanorma::Ietf::Data::VERSION).not_to be nil
  end

  it "workgroup exists and valid json" do
    lib_path = File.join(File.dirname(__FILE__), "..", "..", "..", "lib")
    json = File.join(lib_path, "metanorma", "ietf", "data", "workgroups.json")

    expect { JSON.parse(File.read(json)) }.not_to raise_error
  end

  it "WORKGROUPS not empty" do
    expect(Metanorma::Ietf::Data::WORKGROUPS).not_to be_empty
  end
end
