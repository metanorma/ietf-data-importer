# frozen_string_literal: true

require "yaml"
require "metanorma/ietf/data"

RSpec.describe Metanorma::Ietf::Data do
  it "has a version number" do
    expect(Metanorma::Ietf::Data::VERSION).not_to be nil
  end

  context "with test data" do
    before do
      # Create a mock YAML file with test data
      lib_path = File.join(File.dirname(__FILE__), "..", "..", "..", "lib")
      yaml_path = File.join(lib_path, "metanorma", "ietf", "data", "groups.yaml")

      # Only create the test file if it doesn't exist
      unless File.exist?(yaml_path)
        test_data = {
          "groups" => [
            {
              "abbreviation" => "httpbis",
              "name" => "HTTP",
              "organization" => "ietf",
              "type" => "wg",
              "area" => "Applications and Real-Time Area",
              "status" => "active",
              "description" => "The HTTP working group is chartered to maintain and develop the HTTP protocol",
              "chairs" => ["Chair Person 1", "Chair Person 2"],
              "mailing_list" => "httpbis@ietf.org",
              "mailing_list_archive" => "https://mailarchive.ietf.org/arch/browse/httpbis/",
              "website_url" => "https://httpwg.org/",
              "charter_url" => "https://datatracker.ietf.org/wg/httpbis/about/"
            },
            {
              "abbreviation" => "icnrg",
              "name" => "Information-Centric Networking",
              "organization" => "irtf",
              "type" => "rg",
              "status" => "active",
              "description" => "The research group investigates Information-Centric Networking",
              "chairs" => ["Chair Person 3"],
              "mailing_list" => "icnrg@irtf.org",
              "website_url" => "https://irtf.org/icnrg"
            }
          ]
        }
        FileUtils.mkdir_p(File.dirname(yaml_path))
        File.write(yaml_path, test_data.to_yaml)
      end
    end

    it "loads groups successfully" do
      expect(Metanorma::Ietf::Data.groups).not_to be_empty
    end

    it "finds a group by abbreviation" do
      expect(Metanorma::Ietf::Data.group_exists?("httpbis")).to be true
      expect(Metanorma::Ietf::Data.find_group("httpbis")).not_to be nil
      expect(Metanorma::Ietf::Data.find_group("httpbis").name).to eq("HTTP")
    end

    it "supports filtering by organization" do
      expect(Metanorma::Ietf::Data.ietf_groups).not_to be_empty
      expect(Metanorma::Ietf::Data.irtf_groups).not_to be_empty
      expect(Metanorma::Ietf::Data.ietf_groups.first.organization).to eq("ietf")
      expect(Metanorma::Ietf::Data.irtf_groups.first.organization).to eq("irtf")
    end

    it "supports filtering by type" do
      expect(Metanorma::Ietf::Data.working_groups).not_to be_empty
      expect(Metanorma::Ietf::Data.research_groups).not_to be_empty
      expect(Metanorma::Ietf::Data.working_groups.first.type).to eq("wg")
      expect(Metanorma::Ietf::Data.research_groups.first.type).to eq("rg")
    end

    it "supports filtering by status" do
      expect(Metanorma::Ietf::Data.active_groups).not_to be_empty
      expect(Metanorma::Ietf::Data.active_groups.first.status).to eq("active")
    end
  end

  context "without data file" do
    before do
      # Stub the load_groups method to return an empty collection
      allow(Metanorma::Ietf::Data).to receive(:load_groups).and_return(
        Metanorma::Ietf::Data::GroupCollection.new(groups: [])
      )
    end

    it "returns empty groups" do
      expect(Metanorma::Ietf::Data.groups).to be_empty
    end

    it "returns false for group_exists?" do
      expect(Metanorma::Ietf::Data.group_exists?("any")).to be false
    end

    it "returns nil for find_group" do
      expect(Metanorma::Ietf::Data.find_group("any")).to be nil
    end
  end
end
