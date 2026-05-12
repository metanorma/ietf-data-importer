# frozen_string_literal: true

require "ietf/data/importer"

RSpec.describe Ietf::Data::Importer::Group do
  subject(:group) do
    described_class.new(
      abbreviation: "httpbis",
      name: "HTTP",
      organization: "ietf",
      type: "wg",
      area: "Applications and Real-Time Area",
      status: "active",
      description: "HTTP working group",
      chairs: ["Chair One", "Chair Two"],
      mailing_list: "httpbis@ietf.org",
      mailing_list_archive: "https://mailarchive.ietf.org/arch/browse/httpbis/",
      website_url: "https://httpwg.org/",
      charter_url: "https://datatracker.ietf.org/wg/httpbis/about/",
    )
  end

  describe "attributes" do
    it "exposes all attributes" do
      expect(group.abbreviation).to eq("httpbis")
      expect(group.name).to eq("HTTP")
      expect(group.organization).to eq("ietf")
      expect(group.type).to eq("wg")
      expect(group.area).to eq("Applications and Real-Time Area")
      expect(group.status).to eq("active")
      expect(group.description).to eq("HTTP working group")
      expect(group.chairs).to eq(["Chair One", "Chair Two"])
      expect(group.mailing_list).to eq("httpbis@ietf.org")
      expect(group.mailing_list_archive).to eq("https://mailarchive.ietf.org/arch/browse/httpbis/")
      expect(group.website_url).to eq("https://httpwg.org/")
      expect(group.charter_url).to eq("https://datatracker.ietf.org/wg/httpbis/about/")
    end
  end

  describe "status predicates" do
    describe "#active?" do
      it { expect(group).to be_active }

      it "returns false for non-active status" do
        group.status = "concluded"
        expect(group).not_to be_active
      end
    end

    describe "#concluded?" do
      it "returns false for active group" do
        expect(group).not_to be_concluded
      end

      it "returns true when concluded" do
        group.status = "concluded"
        expect(group).to be_concluded
      end
    end

    describe "#bof?" do
      it "returns true for bof status" do
        group.status = "bof"
        expect(group).to be_bof
      end
    end

    describe "#proposed?" do
      it "returns true for proposed status" do
        group.status = "proposed"
        expect(group).to be_proposed
      end
    end
  end

  describe "organization predicates" do
    describe "#ietf?" do
      it { expect(group).to be_ietf }

      it "returns false for irtf" do
        group.organization = "irtf"
        expect(group).not_to be_ietf
      end
    end

    describe "#irtf?" do
      it "returns false for ietf group" do
        expect(group).not_to be_irtf
      end

      it "returns true for irtf group" do
        group.organization = "irtf"
        expect(group).to be_irtf
      end
    end
  end

  describe "type predicates" do
    describe "#working_group?" do
      it { expect(group).to be_working_group }

      it "returns false for non-wg type" do
        group.type = "rg"
        expect(group).not_to be_working_group
      end
    end

    describe "#research_group?" do
      it "returns false for wg type" do
        expect(group).not_to be_research_group
      end

      it "returns true for rg type" do
        group.type = "rg"
        expect(group).to be_research_group
      end
    end
  end

  describe "YAML round-trip" do
    it "serializes and deserializes correctly" do
      yaml = group.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.abbreviation).to eq(group.abbreviation)
      expect(restored.name).to eq(group.name)
      expect(restored.organization).to eq(group.organization)
      expect(restored.type).to eq(group.type)
      expect(restored.status).to eq(group.status)
      expect(restored.chairs).to eq(group.chairs)
    end
  end

  describe "JSON round-trip" do
    it "serializes and deserializes correctly" do
      json = group.to_json
      restored = described_class.from_json(json)

      expect(restored.abbreviation).to eq(group.abbreviation)
      expect(restored.name).to eq(group.name)
      expect(restored.chairs).to eq(group.chairs)
    end
  end

  describe "constants" do
    it "defines valid organizations" do
      expect(described_class::ORGANIZATIONS).to eq(%w[ietf irtf])
    end

    it "defines valid statuses" do
      expect(described_class::STATUSES).to eq(%w[active concluded bof proposed])
    end

    it "defines valid types" do
      expect(described_class::TYPES).to include("wg", "rg", "area", "team",
                                                "program", "dir", "ag")
    end
  end
end
