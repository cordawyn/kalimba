require "spec_helper"

describe Kalimba::Resource do
  before :all do
    class ResourceTestPerson < Human
      type "http://schema.org/ResourceTestPerson"
      base_uri "http://example.org/people"
    end
  end

  describe "extended class" do
    subject { ResourceTestPerson }

    it { should respond_to :type }
    it { should respond_to :properties }

    describe "properties" do
      subject { ResourceTestPerson.properties }

      it { should be_a Hash }

      %w(name duties).each do |name|
        it { should include name }
      end
    end

    describe "instance" do
      let(:person) { ResourceTestPerson.new }
      subject { person }

      it { should respond_to :name }
      it { should respond_to :name= }
      it { should respond_to :duties }
      it { should respond_to :duties= }

      it { should respond_to :to_model }
      it { should respond_to :to_key }
      it { should respond_to :to_param }

      it { should respond_to :attributes }

      it { should_not eql ResourceTestPerson.new }

      context "created via 'for'" do
        subject { ResourceTestPerson.for "charlie" }

        it { should be_a ResourceTestPerson }

        it "should set subject to the given URI" do
          expect(subject.subject).to eql URI("http://example.org/people/#charlie")
        end

        it { should eql ResourceTestPerson.for("charlie") }
      end

      describe "serialization" do
        describe "to_rdf" do
          subject { person.to_rdf }

          context "for a new record" do
            let(:person) { ResourceTestPerson.new }

            it { should be_nil }
          end

          context "for a persisted record or new record with a subject" do
            let(:person) { ResourceTestPerson.for("alice") }

            it { should be_a URI }

            it { should eql person.subject }
          end
        end
      end

      describe "attributes" do
        subject { person.attributes }

        it { should be_a Hash }

        %w(name duties).each do |name|
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
          before { person.assign_attributes(:duties => %w(eat sleep drink), :name => "Alice") }

          it "should have accessors return the assigned values" do
            expect(person.name).to eql "Alice"
            expect(person.duties).to eql %w(eat sleep drink)
          end
        end

        context "when assigned on initialization" do
          let(:person) { ResourceTestPerson.new(:name => "Bob", :duties => ["running"]) }

          it "should have accessors return the assigned values" do
            expect(person.name).to eql "Bob"
            expect(person.duties).to eql %w(running)
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
