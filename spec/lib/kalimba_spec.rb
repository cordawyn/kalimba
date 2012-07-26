require "spec_helper"

describe Kalimba do
  subject { described_class }

  it { should respond_to :repositories }

  describe "repositories" do
    subject { described_class.repositories }

    it { should be_a Hash }
  end

  describe "add_repository" do
    it "should add a repository instance" do
      expect { Kalimba.add_repository(:extra) }.to change(Kalimba.repositories, :size).by(1)
      expect(Kalimba.repositories[:extra]).to be_a ::Redlander::Model
    end
  end
end
