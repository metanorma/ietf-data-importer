# frozen_string_literal: true

require "yaml"
require "ietf/data/importer"

RSpec.describe Ietf::Data::Importer do
  # Helper to get the path to our fixture files
  def fixture_path(fixture_name = "ietf_groups.yaml")
    spec_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
    File.join(spec_dir, "fixtures", fixture_name)
  end

  # Define fixture data with let
  let(:ietf_groups_data) { YAML.load_file(fixture_path("ietf_groups.yaml")) }
  let(:test_groups_data) { YAML.load_file(fixture_path("test_groups.yaml")) }
  it "has a version number" do
    expect(Ietf::Data::Importer::VERSION).not_to be nil
  end

  context "with ietf_groups fixture" do
    # Load data from the fixture instead of writing to disk
    let(:groups_collection) do
      # Use a stub to make the Importer use our fixture data
      allow(Ietf::Data::Importer).to receive(:load_groups).and_return(
        Ietf::Data::Importer::GroupCollection.new(groups: ietf_groups_data["groups"])
      )
      Ietf::Data::Importer.groups
    end

    before do
      # Clear any cached groups that might be present
      Ietf::Data::Importer.class_variable_set(:@@groups, nil) if Ietf::Data::Importer.class_variable_defined?(:@@groups)

      # Set up the stub to use fixture data
      allow(Ietf::Data::Importer).to receive(:load_groups).and_return(
        Ietf::Data::Importer::GroupCollection.new(groups: ietf_groups_data["groups"])
      )
    end

    it "loads groups successfully from fixture" do
      expect(Ietf::Data::Importer.groups).not_to be_empty
    end

    it "finds a group by abbreviation" do
      expect(Ietf::Data::Importer.group_exists?("artart")).to be true
      expect(Ietf::Data::Importer.find_group("artart")).not_to be nil
      expect(Ietf::Data::Importer.find_group("artart").name).to eq("ART Area Review Team")
    end

    it "supports filtering by organization" do
      expect(Ietf::Data::Importer.ietf_groups).not_to be_empty
      expect(Ietf::Data::Importer.ietf_groups.first.organization).to eq("ietf")
    end

    it "supports filtering by type" do
      expect(Ietf::Data::Importer.working_groups).not_to be_empty
      wg = Ietf::Data::Importer.working_groups.find { |g| g.type == "wg" }
      expect(wg).not_to be_nil
    end

    it "supports filtering by status" do
      expect(Ietf::Data::Importer.active_groups).not_to be_empty
      expect(Ietf::Data::Importer.active_groups.first.status).to eq("active")
    end
  end

  context "with test_groups fixture" do
    before do
      # Clear any cached groups that might be present
      Ietf::Data::Importer.class_variable_set(:@@groups, nil) if Ietf::Data::Importer.class_variable_defined?(:@@groups)

      # Set up the stub to use test fixture data
      allow(Ietf::Data::Importer).to receive(:load_groups).and_return(
        Ietf::Data::Importer::GroupCollection.new(groups: test_groups_data["groups"])
      )
    end

    it "loads test group successfully" do
      expect(Ietf::Data::Importer.groups).not_to be_empty
      expect(Ietf::Data::Importer.groups.first.name).to eq("Test Group")
    end

    it "finds test group by abbreviation" do
      expect(Ietf::Data::Importer.group_exists?("testgroup")).to be true
      expect(Ietf::Data::Importer.find_group("testgroup")).not_to be nil
      expect(Ietf::Data::Importer.find_group("testgroup").description).to include("test group for command validation")
    end
  end

  context "with direct fixture loading" do
    # This demonstrates how to load a fixture directly without stubbing
    let(:direct_collection) do
      yaml_data = YAML.load_file(fixture_path("test_groups.yaml"))
      Ietf::Data::Importer::GroupCollection.new(groups: yaml_data["groups"])
    end

    it "can load collection directly from fixture" do
      expect(direct_collection.groups).not_to be_empty
      expect(direct_collection.groups.first.abbreviation).to eq("testgroup")
    end
  end

  context "without data file" do
    before do
      # Stub the load_groups method to return an empty collection
      allow(Ietf::Data::Importer).to receive(:load_groups).and_return(
        Ietf::Data::Importer::GroupCollection.new(groups: [])
      )
    end

    it "returns empty groups" do
      expect(Ietf::Data::Importer.groups).to be_empty
    end

    it "returns false for group_exists?" do
      expect(Ietf::Data::Importer.group_exists?("any")).to be false
    end

    it "returns nil for find_group" do
      expect(Ietf::Data::Importer.find_group("any")).to be nil
    end
  end
end
