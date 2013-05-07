require "spec_helper"

describe "reflection" do
  before :all do
    class ReflectionTestOilRig < Kalimba::Resource
      type "http://schema.org/ReflectionTestOilRig"
      base_uri "http://example.org/reflection_oil_rigs"

      has_many :neighbours, :predicate => "http://example.org/reflection_oil_rigs", :datatype => :ReflectionTestOilRig
      has_many :saboteurs, :predicate => "http://example.org/reflection_saboteur", :datatype => "http://schema.org/ReflectionTestSaboteur"
    end
  end

  subject { ReflectionTestOilRig.reflections }

  context "for a non-Kalimba resource" do
    it { should_not have_key :saboteurs }
  end

  context "for a Kalimba::Resource association" do
    it { should have_key :neighbours }

    context ":neighbours" do
      subject { ReflectionTestOilRig.reflect_on_association(:neighbours) }

      it "should have proper accessors" do
        expect(subject.macro).to eql :has_many
        expect(subject.name).to eql :neighbours
        expect(subject.options[:class_name]).to eql ReflectionTestOilRig
      end
    end
  end
end
