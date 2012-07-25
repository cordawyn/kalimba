require "spec_helper"

describe ActiveRedlander::Resource do
  before :all do
    class ResourceTestPerson
      include Human
      include Engineer
      base_uri "http://example.org/people"
    end
  end

  subject { Human }

  it { should respond_to :type }

  describe "extended class" do
    subject { ResourceTestPerson }

    it { should_not respond_to :type }

    it { should respond_to :types }
    it { should respond_to :properties }
    it { should respond_to :repository }

    describe "types" do
      subject { ResourceTestPerson.types }

      it { should be_a Set }

      it { should include URI("http://schema.org/Human") }
      it { should include URI("http://schema.org/Engineer") }
    end

    describe "properties" do
      subject { ResourceTestPerson.properties }

      it { should be_a Hash }

      %w(name rank duties).each do |name|
        it { should include name }
      end
    end

    describe "repository" do
      subject { ResourceTestPerson.repository }

      it { should be_a ::Redlander::Model }
      it { should eql ActiveRedlander.repositories[:default] }
    end

    describe "instance" do
      let(:person) { ResourceTestPerson.new }
      subject { person }

      it { should respond_to :name }
      it { should respond_to :name= }
      it { should respond_to :rank }
      it { should respond_to :rank= }
      it { should respond_to :duties }
      it { should respond_to :duties= }

      it { should respond_to :to_model }
      it { should respond_to :to_key }
      it { should respond_to :to_param }

      it { should respond_to :attributes }

      describe "attributes" do
        subject { person.attributes }

        it { should be_a Hash }
      end

      context "with changes" do
        before { subject.name = "Bob" }

        it { should be_changed }

        it "should have changed attributes marked" do
          expect(person.changes).to include "name"
        end

        context "after save" do
          before { subject.save }

          it { should_not be_changed }
        end
      end
    end
  end
end
