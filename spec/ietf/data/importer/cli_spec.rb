# frozen_string_literal: true

require "ietf/data/importer"
require "tmpdir"

RSpec.describe Ietf::Data::Importer::Cli do
  def project_root
    File.expand_path("../../../..", __dir__)
  end

  def groups_yaml_path
    File.join(project_root, "lib", "ietf", "data", "importer", "groups.yaml")
  end

  def fixture_path(name)
    File.join(project_root, "spec", "fixtures", name)
  end

  let(:test_groups) do
    [
      Ietf::Data::Importer::Group.new(
        abbreviation: "test", name: "Test", organization: "ietf",
        type: "wg", status: "active"
      ),
    ]
  end

  let(:test_collection) do
    Ietf::Data::Importer::GroupCollection.new(groups: test_groups)
  end

  describe "fetch command" do
    it "scrapes and saves to YAML file" do
      allow(Ietf::Data::Importer::Scrapers).to receive(:fetch_all).and_return(test_collection)

      Dir.mktmpdir do |dir|
        output = File.join(dir, "output.yaml")
        described_class.start(["fetch", output])

        loaded = Ietf::Data::Importer::GroupCollection.from_file(output)
        expect(loaded.size).to eq(1)
        expect(loaded.first.abbreviation).to eq("test")
      end
    end

    it "scrapes and saves to JSON file" do
      allow(Ietf::Data::Importer::Scrapers).to receive(:fetch_all).and_return(test_collection)

      Dir.mktmpdir do |dir|
        output = File.join(dir, "output.json")
        described_class.start(["fetch", output, "--format=json"])

        loaded = Ietf::Data::Importer::GroupCollection.from_file(output,
                                                                 format: :json)
        expect(loaded.size).to eq(1)
        expect(loaded.first.abbreviation).to eq("test")
      end
    end
  end

  describe "integrate command" do
    it "validates YAML and writes to gem directory" do
      fixture = fixture_path("test_groups.yaml")
      target = groups_yaml_path
      backup = File.read(target)

      described_class.start(["integrate", fixture])

      loaded = Ietf::Data::Importer::GroupCollection.from_file(target)
      expect(loaded.size).to eq(1)
      expect(loaded.first.abbreviation).to eq("testgroup")
    ensure
      File.write(target, backup)
    end

    it "exits with error for invalid YAML" do
      expect do
        Dir.mktmpdir do |dir|
          bad = File.join(dir, "bad.yaml")
          File.write(bad, "not: valid\n  broken: [\n")
          described_class.start(["integrate", bad])
        end
      end.to raise_error(SystemExit)
    end
  end
end
