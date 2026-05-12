# frozen_string_literal: true

require "ietf/data/importer"

RSpec.describe Ietf::Data::Importer do
  let(:test_groups) do
    [
      Ietf::Data::Importer::Group.new(
        abbreviation: "httpbis", name: "HTTP", organization: "ietf",
        type: "wg", area: "ART", status: "active"
      ),
      Ietf::Data::Importer::Group.new(
        abbreviation: "cfrg", name: "CFRG", organization: "irtf",
        type: "rg", status: "active"
      ),
      Ietf::Data::Importer::Group.new(
        abbreviation: "oldwg", name: "Old WG", organization: "ietf",
        type: "wg", area: "OPS", status: "concluded"
      ),
    ]
  end

  let(:test_collection) do
    Ietf::Data::Importer::GroupCollection.new(groups: test_groups)
  end

  it "has a version number" do
    expect(described_class::VERSION).to eq("0.3.0")
  end

  describe "query delegation", :query_tests do
    before do
      allow(described_class).to receive(:collection).and_return(test_collection)
    end

    describe ".collection" do
      it "returns a GroupCollection" do
        expect(described_class.collection).to be_a(Ietf::Data::Importer::GroupCollection)
      end
    end

    describe ".groups" do
      it "returns all groups from the collection" do
        expect(described_class.groups.size).to eq(3)
      end
    end

    describe ".find_group" do
      it "finds a group by abbreviation" do
        group = described_class.find_group("httpbis")
        expect(group.name).to eq("HTTP")
      end

      it "returns nil for missing group" do
        expect(described_class.find_group("nonexistent")).to be_nil
      end
    end

    describe ".group_exists?" do
      it "returns true for existing group" do
        expect(described_class.group_exists?("httpbis")).to be true
      end

      it "returns false for missing group" do
        expect(described_class.group_exists?("nonexistent")).to be false
      end
    end

    describe ".ietf_groups" do
      it "returns a GroupCollection of IETF groups" do
        result = described_class.ietf_groups
        expect(result).to be_a(Ietf::Data::Importer::GroupCollection)
        expect(result.groups).to all(satisfy(&:ietf?))
      end
    end

    describe ".irtf_groups" do
      it "returns a GroupCollection of IRTF groups" do
        result = described_class.irtf_groups
        expect(result).to be_a(Ietf::Data::Importer::GroupCollection)
        expect(result.groups).to all(satisfy(&:irtf?))
      end
    end

    describe ".working_groups" do
      it "returns a GroupCollection of WGs" do
        result = described_class.working_groups
        expect(result).to be_a(Ietf::Data::Importer::GroupCollection)
        expect(result.groups).to all(satisfy(&:working_group?))
      end
    end

    describe ".research_groups" do
      it "returns a GroupCollection of RGs" do
        result = described_class.research_groups
        expect(result).to be_a(Ietf::Data::Importer::GroupCollection)
        expect(result.groups).to all(satisfy(&:research_group?))
      end
    end

    describe ".groups_by_type" do
      it "returns a GroupCollection filtered by type" do
        result = described_class.groups_by_type("wg")
        expect(result).to be_a(Ietf::Data::Importer::GroupCollection)
        expect(result.size).to eq(2)
      end
    end

    describe ".groups_by_area" do
      it "returns a GroupCollection filtered by area" do
        result = described_class.groups_by_area("ART")
        expect(result).to be_a(Ietf::Data::Importer::GroupCollection)
        expect(result.size).to eq(1)
      end
    end

    describe ".active_groups" do
      it "returns a GroupCollection of active groups" do
        result = described_class.active_groups
        expect(result).to be_a(Ietf::Data::Importer::GroupCollection)
        expect(result.groups).to all(satisfy(&:active?))
      end
    end

    describe ".concluded_groups" do
      it "returns a GroupCollection of concluded groups" do
        result = described_class.concluded_groups
        expect(result).to be_a(Ietf::Data::Importer::GroupCollection)
        expect(result.size).to eq(1)
        expect(result.first.abbreviation).to eq("oldwg")
      end
    end

    describe ".group_types" do
      it "returns sorted unique types" do
        expect(described_class.group_types).to eq(%w[rg wg])
      end
    end

    describe ".areas" do
      it "returns sorted unique areas" do
        expect(described_class.areas).to eq(%w[ART OPS])
      end
    end

    describe ".load_groups" do
      it "returns the collection" do
        expect(described_class.load_groups).to be_a(Ietf::Data::Importer::GroupCollection)
      end
    end
  end

  describe ".reset!" do
    after { described_class.reset! }

    it "causes the next .collection call to create a new instance" do
      first = described_class.collection
      described_class.reset!
      second = described_class.collection
      expect(first).not_to equal(second)
    end
  end
end
