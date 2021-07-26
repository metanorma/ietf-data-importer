# frozen_string_literal: true

require "json"

RSpec.describe Metanorma::Ietf::Data do
  it "has a version number" do
    expect(Metanorma::Ietf::Data::VERSION).not_to be nil
  end

  it "workgroup exists and valid json" do
    lib_path = File.join(File.dirname(__FILE__), "..", "..", "..", "lib")
    wg_json = File.join(lib_path, "metanorma", "ietf", "data", "workgroup.json")
    
    expect { JSON.parse(File.read(wg_json)) }.not_to raise_error
  end
end
