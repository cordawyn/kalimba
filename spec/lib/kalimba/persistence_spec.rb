require "spec_helper"

describe Kalimba::Persistence do
  before :all do
    class PersistenceTestPerson < Engineer
      type "http://schema.org/PersistenceTestPerson"
      base_uri "http://example.org/people"
    end

    class PersistenceTestOilRig < Kalimba::Resource
      type "http://schema.org/OilRig"
      base_uri "http://example.org/oil_rigs"

      property :safe, :predicate => "http://example.org/safe", :datatype => NS::XMLSchema["boolean"]
      property :operator, :predicate => "http://example.org/operator", :datatype => :PersistenceTestPerson
      has_many :saboteurs, :predicate => "http://example.org/saboteur", :datatype => "http://schema.org/Saboteur"
    end
  end

  describe "associations" do
    before { PersistenceTestOilRig.create }
    let(:rig) { PersistenceTestOilRig.first }

    describe "instantiation" do
      context "of existing Kalimba resources" do
        before do
          Kalimba.repository.statements.create(:subject => rig.subject,
                                               :predicate => PersistenceTestOilRig.properties["operator"][:predicate],
                                               :object => PersistenceTestPerson.create.subject)
        end

        subject { rig.operator }

        it { should be_an_instance_of(PersistenceTestPerson) }
      end

      context "of unknown Kalimba resources" do
        before do
          Kalimba.repository.statements.create(:subject => rig.subject,
                                               :predicate => PersistenceTestOilRig.properties["saboteurs"][:predicate],
                                               :object => URI("http://schema.org/Saboteur#Karen_Knight"))
          Kalimba.repository.statements.create(:subject => rig.subject,
                                               :predicate => PersistenceTestOilRig.properties["saboteurs"][:predicate],
                                               :object => URI("http://schema.org/Saboteur#Lee_Knight"))
        end

        subject { rig.saboteurs }

        it { should be_a(Enumerable) }

        it "should yield anonymous class instances" do
          expect(subject.first.class).to be_anonymous
        end

        it "should add the anonymous class to RDFSClass repository" do
          subject
          expect(Kalimba::Resource.descendants).to include(subject.first.class)
        end

        it "should not create more than one anonymous class for homogenious objects" do
          expect(subject.first.class).to eql subject.last.class
        end

        it "should set class type to the declared datatype" do
          expect(subject.first.class.type).to eql PersistenceTestOilRig.properties["saboteurs"][:datatype]
        end

        it "should set class base_uri to the URI of the instance (without the fragment)" do
          expect(subject.first.class.base_uri).to eql URI("http://schema.org/Saboteur/")
        end
      end
    end
  end

  describe "count" do
    subject { PersistenceTestPerson.count }

    before do
      3.times { PersistenceTestPerson.create }
    end

    it { should eql 3 }
  end

  describe "find" do
    let(:options) { {:conditions => {:rank => 4}} }

    context "when records are found" do
      before do
        PersistenceTestPerson.create(:rank => 4, :duties => %w(sex sleep eat drink dream))
      end

      describe ":first" do
        subject { PersistenceTestPerson.find(:first, options) }

        it { should be_a PersistenceTestPerson }
      end

      describe ":all" do
        subject { PersistenceTestPerson.find(:all, options) }

        it { should be_a Enumerable }
        it "should return an array of found entries" do
          subject.size.should eql 1
          subject.first.should be_a PersistenceTestPerson
        end
      end
    end

    context "when records are not found" do
      before do
        PersistenceTestPerson.create(:rank => 0, :duties => %w(sex sleep eat drink dream))
      end

      describe ":first" do
        subject { PersistenceTestPerson.find(:first, options) }

        it { should be_nil }
      end

      describe ":all" do
        subject { PersistenceTestPerson.find(:all, options) }

        it { should be_empty }
      end
    end
  end

  describe "create" do
    let(:person) { PersistenceTestPerson.create }
    subject { person }

    it { should be_a Kalimba::Resource }

    it "should persist the instance" do
      subject.should be_persisted
      subject.should_not be_new_record
    end
  end

  describe "destroy_all" do
    before do
      2.times { PersistenceTestPerson.create }
    end

    it "should destroy all instances of the given RDFS class" do
      expect { PersistenceTestPerson.destroy_all }.to change(Kalimba.repository, :size).by(-2)
    end

    it "should not destroy instances of other RDFS classes" do
      rig = PersistenceTestOilRig.create
      PersistenceTestPerson.destroy_all
      expect(PersistenceTestOilRig.exist?).to be_true
    end
  end

  describe "exist?" do
    subject { PersistenceTestPerson.exist? }

    context "when there are no RDFS class instances in the repository" do
      before { PersistenceTestPerson.new }

      it { should be_false }
    end

    context "when there are RDFS class instances in the repository" do
      before { PersistenceTestPerson.create }

      it { should be_true }
    end
  end

  describe "new record" do
    let(:person) { PersistenceTestPerson.new }
    subject { person }

    it { should be_new_record }
    it { should_not be_persisted }

    describe "subject" do
      subject { person.subject }

      it { should be_nil }

      context "after save" do
        before { person.save }

        it { should be_a URI }
      end
    end

    describe "save" do
      it "should return true" do
        expect(person.save).to be_true
      end

      it "should persist the record" do
        person.save
        person.should_not be_new_record
        person.should_not be_changed
        person.should be_persisted
      end

      context "when failed halfway" do
        # TODO: need a more "natural" method of causing an error on save
        before { person.stub(store_type: false) }

        it "should not leave remains in the repository" do
          person.save
          Kalimba.repository.statements.exist?(subject: person.subject).should be_false
        end
      end
    end

    context "with changes" do
      context "when saved" do
        it "should have values type cast" do
          person.rank = "2"
          expect {
            person.save && person.reload
          }.to change(person, :rank).from("2").to(2)
        end

        it "should not persist non-castable values" do
          person.retired = true
          expect(person.save).to be_true

          person.reload
          expect(person.retired).to be_nil
        end
      end

      context "to a single value" do
        before { person.rank = 1 }

        context "when saved" do
          before { subject.save }

          it "should be added statements with changed attributes (type + rank)" do
            expect(Kalimba.repository.size).to eql 2
          end
        end
      end

      context "to an association" do
        let(:charlie) { PersistenceTestPerson.for("charlie") }
        before do
          charlie.rank = 99
          person.boss = charlie
        end

        context "when saved" do
          before { subject.save }

          it "should persist the association" do
            charlie.should_not be_new_record
            charlie.should be_persisted
            charlie.should_not be_changed
          end
        end
      end

      context "to collections of non-Kalimba resources" do
        before { person.duties = %w(building designing) }

        context "when saved" do
          before { person.save }

          it "should be added statements with changed attributes (type + duties*2)" do
            expect(Kalimba.repository.size).to eql 3
          end

          it "should include the collection" do
            person.reload
            expect(person.duties).to eql %w(building designing)
          end
        end
      end

      context "to collections of Kalimba resources" do
        before do
          @berk = Engineer.for("Berk")
          person.coworkers = [@berk]
        end

        context "when saved" do
          before { person.save }

          it "should retain the list of coworkers" do
            person.reload
            expect(person.coworkers).to eql [@berk]
          end
        end
      end
    end

    describe "reload" do
      subject { PersistenceTestPerson.for(person.id) }

      context "with related data in the storage" do
        before { person.update_attributes(:rank => 7, :duties => %w(idling procrastinating)) }

        it "should assign attributes the values from the storage" do
          expect { subject.reload }.to change { subject.attributes["rank"] }.from(nil).to(7)
        end

        it "should assign attributes the collections from the storage" do
          expect { subject.reload }.to change { subject.attributes["duties"] }.from([]).to(%w(idling procrastinating))
        end

        context "when accessing an attribute" do
          it "should retrieve it from the storage" do
            expect { subject.rank }.to change { subject.attributes["rank"] }.from(nil).to(7)
          end
        end
      end
    end
  end

  describe "already persisted record" do
    let(:person) { PersistenceTestPerson.create }
    subject { person }

    it { should_not be_new_record }
    it { should be_persisted }

    describe "subject" do
      subject { person.subject }

      it { should be_a URI }
    end

    describe "destroy" do
      before { @another = PersistenceTestPerson.create }

      it "should remove the record from the storage" do
        subject # create subject
        expect { subject.destroy }.to change(Kalimba.repository, :size).by(-1)
        subject.should_not be_new_record
        subject.should_not be_persisted
        subject.should be_destroyed
        subject.should be_frozen
      end

      it "should not remove other records from the storage" do
        subject.destroy
        expect(Kalimba.repository.statements.exist?(:subject => @another.subject)).to be_true
      end
    end

    describe "update_attributes" do
      subject { person.update_attributes(:rank => 9) }

      it { should be_true }

      it "should assign the given attributes" do
        expect { person.update_attributes(:rank => 0) }.to change(person, :rank).to(0)
      end

      it "should have no changes" do
        expect(person.changes).to be_empty
      end
    end
  end
end
