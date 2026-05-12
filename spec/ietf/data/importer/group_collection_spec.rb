# frozen_string_literal: true

require "ietf/data/importer"
require "tmpdir"

RSpec.describe Ietf::Data::Importer::GroupCollection do
  let(:httpbis) do
    Ietf::Data::Importer::Group.new(
      abbreviation: "httpbis", name: "HTTP", organization: "ietf",
      type: "wg", area: "Applications and Real-Time Area", status: "active",
      chairs: ["Chair A"]
    )
  end

  let(:cfrg) do
    Ietf::Data::Importer::Group.new(
      abbreviation: "cfrg", name: "CFRG", organization: "irtf",
      type: "rg", status: "active"
    )
  end

  let(:oldwg) do
    Ietf::Data::Importer::Group.new(
      abbreviation: "oldwg", name: "Old WG", organization: "ietf",
      type: "wg", area: "Operations and Management Area", status: "concluded",
      concluded_date: Date.new(2020, 1, 1)
    )
  end

  let(:collection) { described_class.new(groups: [httpbis, cfrg, oldwg]) }

  describe "Enumerable" do
    it "is enumerable" do
      expect(collection).to be_a(Enumerable)
    end

    it "iterates over groups" do
      abbreviations = collection.map(&:abbreviation)
      expect(abbreviations).to eq(%w[httpbis cfrg oldwg])
    end

    it "supports select" do
      active = collection.select(&:active?)
      expect(active.size).to eq(2)
    end

    it "supports count" do
      expect(collection.count).to eq(3)
    end
  end

  describe "#size and #empty?" do
    it "returns size" do
      expect(collection.size).to eq(3)
    end

    it "returns false for empty?" do
      expect(collection).not_to be_empty
    end

    it "returns true for empty? on empty collection" do
      empty = described_class.new(groups: [])
      expect(empty).to be_empty
    end
  end

  describe "#[] and #find_by_abbreviation" do
    it "finds group by abbreviation" do
      expect(collection.find_by_abbreviation("httpbis")).to eq(httpbis)
    end

    it "finds case-insensitively" do
      expect(collection.find_by_abbreviation("HTTPBIS")).to eq(httpbis)
    end

    it "returns nil for missing abbreviation" do
      expect(collection.find_by_abbreviation("nonexistent")).to be_nil
    end

    it "supports bracket access" do
      expect(collection["cfrg"]).to eq(cfrg)
    end
  end

  describe "#exists?" do
    it "returns true for existing group" do
      expect(collection.exists?("httpbis")).to be true
    end

    it "returns false for missing group" do
      expect(collection.exists?("nonexistent")).to be false
    end

    it "is case insensitive" do
      expect(collection.exists?("CFRG")).to be true
    end
  end

  describe "#by_organization" do
    it "returns IETF groups" do
      result = collection.by_organization("ietf")
      expect(result).to be_a(described_class)
      expect(result.size).to eq(2)
      expect(result.groups).to all(satisfy(&:ietf?))
    end

    it "returns IRTF groups" do
      result = collection.by_organization("irtf")
      expect(result.size).to eq(1)
      expect(result.groups.first.abbreviation).to eq("cfrg")
    end
  end

  describe "#by_type" do
    it "returns working groups" do
      result = collection.by_type("wg")
      expect(result.size).to eq(2)
    end

    it "returns research groups" do
      result = collection.by_type("rg")
      expect(result.size).to eq(1)
    end

    it "is case insensitive" do
      result = collection.by_type("WG")
      expect(result.size).to eq(2)
    end
  end

  describe "#by_area" do
    it "returns groups in an area" do
      result = collection.by_area("Applications and Real-Time Area")
      expect(result.size).to eq(1)
      expect(result.first.abbreviation).to eq("httpbis")
    end

    it "is case insensitive" do
      result = collection.by_area("applications and real-time area")
      expect(result.size).to eq(1)
    end

    it "excludes groups with nil area" do
      result = collection.by_area("Applications and Real-Time Area")
      result.each { |g| expect(g.area).not_to be_nil }
    end
  end

  describe "#active and #concluded" do
    it "returns active groups" do
      result = collection.active
      expect(result).to be_a(described_class)
      expect(result.size).to eq(2)
      expect(result.groups).to all(satisfy(&:active?))
    end

    it "returns concluded groups" do
      result = collection.concluded
      expect(result.size).to eq(1)
      expect(result.first.abbreviation).to eq("oldwg")
    end
  end

  describe "convenience methods" do
    describe "#working_groups" do
      it "delegates to by_type('wg')" do
        result = collection.working_groups
        expect(result.size).to eq(2)
      end
    end

    describe "#research_groups" do
      it "delegates to by_type('rg')" do
        result = collection.research_groups
        expect(result.size).to eq(1)
      end
    end

    describe "#ietf_groups" do
      it "delegates to by_organization('ietf')" do
        result = collection.ietf_groups
        expect(result.size).to eq(2)
      end
    end

    describe "#irtf_groups" do
      it "delegates to by_organization('irtf')" do
        result = collection.irtf_groups
        expect(result.size).to eq(1)
      end
    end
  end

  describe "#group_types and #areas" do
    it "returns unique sorted types" do
      expect(collection.group_types).to eq(%w[rg wg])
    end

    it "returns unique sorted areas" do
      expect(collection.areas).to eq(["Applications and Real-Time Area",
                                      "Operations and Management Area"])
    end
  end

  describe "query chaining" do
    it "chains filters" do
      result = collection.active.by_type("wg")
      expect(result.size).to eq(1)
      expect(result.first.abbreviation).to eq("httpbis")
    end

    it "chains three filters" do
      result = collection.active.by_organization("ietf").by_type("wg")
      expect(result.size).to eq(1)
      expect(result.first.abbreviation).to eq("httpbis")
    end

    it "returns empty collection when nothing matches" do
      result = collection.concluded.by_type("rg")
      expect(result).to be_empty
    end
  end

  describe "#merge" do
    it "combines two collections" do
      other = described_class.new(groups: [
                                    Ietf::Data::Importer::Group.new(
                                      abbreviation: "new", name: "New", organization: "ietf",
                                      type: "wg", status: "active"
                                    ),
                                  ])

      merged = collection.merge(other)
      expect(merged.size).to eq(4)
      expect(merged).to be_a(described_class)
    end

    it "does not mutate the original" do
      original_size = collection.size
      other = described_class.new(groups: [
                                    Ietf::Data::Importer::Group.new(
                                      abbreviation: "new", name: "New", organization: "ietf",
                                      type: "wg", status: "active"
                                    ),
                                  ])

      collection.merge(other)
      expect(collection.size).to eq(original_size)
    end
  end

  describe ".from_file" do
    it "loads from YAML file" do
      path = File.expand_path("../../../fixtures/test_groups.yaml", __dir__)
      loaded = described_class.from_file(path)

      expect(loaded.size).to eq(1)
      expect(loaded.first.abbreviation).to eq("testgroup")
    end

    it "returns empty collection for missing file" do
      loaded = described_class.from_file("/nonexistent/path.yaml")
      expect(loaded).to be_empty
    end
  end

  describe "#save" do
    it "writes YAML file" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "output.yaml")
        collection.save(path)

        loaded = described_class.from_file(path)
        expect(loaded.size).to eq(3)
        expect(loaded.first.abbreviation).to eq("httpbis")
      end
    end

    it "writes JSON file" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "output.json")
        collection.save(path, format: :json)

        loaded = described_class.from_file(path, format: :json)
        expect(loaded.size).to eq(3)
        expect(loaded.first.abbreviation).to eq("httpbis")
      end
    end

    it "raises on unsupported format" do
      expect do
        collection.save("out.xml", format: :xml)
      end.to raise_error(ArgumentError)
    end
  end

  describe "YAML round-trip" do
    it "preserves all group data" do
      yaml = collection.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.size).to eq(collection.size)
      expect(restored["httpbis"].name).to eq("HTTP")
      expect(restored["httpbis"].chairs).to eq(["Chair A"])
      expect(restored["oldwg"].concluded_date).to eq(Date.new(2020, 1, 1))
    end
  end

  describe "edge cases" do
    describe "empty collection" do
      let(:empty) { described_class.new(groups: []) }

      it "returns empty results for all queries" do
        expect(empty.active).to be_empty
        expect(empty.concluded).to be_empty
        expect(empty.ietf_groups).to be_empty
        expect(empty.irtf_groups).to be_empty
        expect(empty.working_groups).to be_empty
        expect(empty.research_groups).to be_empty
        expect(empty.by_type("wg")).to be_empty
        expect(empty.by_area("ART")).to be_empty
        expect(empty.by_organization("ietf")).to be_empty
      end

      it "returns nil for find_by_abbreviation" do
        expect(empty.find_by_abbreviation("anything")).to be_nil
      end

      it "returns false for exists?" do
        expect(empty.exists?("anything")).to be false
      end

      it "returns empty arrays for group_types and areas" do
        expect(empty.group_types).to eq([])
        expect(empty.areas).to eq([])
      end
    end

    describe "merge with empty collection" do
      it "returns equivalent collection" do
        empty = described_class.new(groups: [])
        merged = collection.merge(empty)
        expect(merged.size).to eq(collection.size)
      end
    end

    describe "merge with duplicate abbreviations" do
      it "preserves both groups" do
        duplicate = described_class.new(groups: [
                                          Ietf::Data::Importer::Group.new(
                                            abbreviation: "httpbis", name: "HTTP Duplicate", organization: "ietf",
                                            type: "wg", status: "active"
                                          ),
                                        ])

        merged = collection.merge(duplicate)
        expect(merged.size).to eq(4)
        httpbis_groups = merged.select { |g| g.abbreviation == "httpbis" }
        expect(httpbis_groups.size).to eq(2)
      end
    end

    describe "groups with nil optional fields" do
      let(:minimal_group) do
        Ietf::Data::Importer::Group.new(
          abbreviation: "min", name: "Minimal", organization: "ietf",
          type: "wg", status: "active"
        )
      end

      it "handles nil area in by_area" do
        c = described_class.new(groups: [minimal_group])
        expect(c.by_area("ART")).to be_empty
      end

      it "handles nil type in by_type" do
        minimal_group.type = nil
        c = described_class.new(groups: [minimal_group])
        expect(c.by_type("wg")).to be_empty
      end

      it "round-trips a minimal group" do
        yaml = described_class.new(groups: [minimal_group]).to_yaml
        restored = described_class.from_yaml(yaml)
        expect(restored.first.abbreviation).to eq("min")
        expect(restored.first.area).to be_nil
      end
    end
  end
end
