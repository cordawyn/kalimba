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

      %w(name rank duties retired).each do |name|
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
      it { should respond_to :retired }
      it { should respond_to :retired= }

      it { should respond_to :to_model }
      it { should respond_to :to_key }
      it { should respond_to :to_param }

      it { should respond_to :attributes }

      context "created via 'for'" do
        subject { ResourceTestPerson.for "http://example.com/people#charlie" }

        it { should be_a ResourceTestPerson }

        it "should set subject to the given URI" do
          expect(subject.subject).to eql URI("http://example.com/people#charlie")
        end
      end

      describe "attributes" do
        subject { person.attributes }

        it { should be_a Hash }

        %w(name rank duties retired).each do |name|
          it { should include name }
        end

        context "when the resource is frozen" do
          before { person.freeze }

          it { should be_frozen }
        end

        describe "collections" do
          it "should be enumerable" do
            expect(person.duties).to be_a Enumerable
            expect(person.attributes["duties"]).to be_a Enumerable
          end
        end

        context "when assigned via assign_attributes" do
          before { person.assign_attributes(:rank => 3, :name => "Alice") }

          it "should have accessors return the assigned values" do
            expect(person.name).to eql "Alice"
            expect(person.rank).to eql 3
            expect(person.duties).to eql []
            expect(person.retired).to be_nil
          end
        end

        context "when assigned on initialization" do
          let(:person) { ResourceTestPerson.new(:name => "Bob", :duties => ["running"]) }

          it "should have accessors return the assigned values" do
            expect(person.name).to eql "Bob"
            expect(person.rank).to be_nil
            expect(person.duties).to eql %w(running)
            expect(person.retired).to be_nil
          end
        end
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
