require "spec_helper"

describe ActiveRedlander do
  subject { described_class }

  it { should respond_to :repositories }

  describe "repositories" do
    subject { described_class.repositories }

    it { should be_a Hash }
  end

  describe "add_repository" do
    it "should add a repository instance" do
      expect { ActiveRedlander.add_repository(:extra) }.to change(ActiveRedlander.repositories, :size).by(1)
      expect(ActiveRedlander.repositories[:extra]).to be_a ::Redlander::Model
    end
  end
end
