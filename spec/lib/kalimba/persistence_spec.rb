require "spec_helper"

describe Kalimba::Persistence do
  before :all do
    module PersistenceTestPerson
      extend Kalimba::RDFSResource
      include Engineer
      type "http://schema.org/Person"
      base_uri "http://example.org/people"
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
          expect(person.save).to be_false
        end
      end

      context "to a single value" do
        before { person.rank = 1 }

        context "when saved" do
          before { subject.save }

          it "should be added statements with changed attributes" do
            expect(Kalimba.repository.statements.size).to eql (person.class.types.size + 1)
          end
        end
      end

      context "to an association" do
        let(:charlie) { PersistenceTestPerson.for("http://example.org/people#charlie") }
        before { person.boss = charlie }

        context "when saved" do
          before { subject.save }

          it "should persist the association" do
            pending
            # TODO: also avoid cyclic saves on associations
            # (by passing parent's subject?)
            charlie.should_not be_new_record
            charlie.should be_persisted
            charlie.should_not be_changed
          end
        end
      end

      context "to collections" do
        before { person.duties = %w(building designing) }

        context "when saved" do
          before { person.save }

          it "should be added statements with changed attributes" do
            expect(Kalimba.repository.statements.size).to eql (person.class.types.size + 2)
          end
        end
      end
    end

    describe "reload" do
      subject { PersistenceTestPerson.new(:_subject => person.subject) }

      context "with related data in the storage" do
        before { person.update_attributes(:rank => 7, :duties => %w(idling procrastinating)) }

        it "should assign attributes the values from the storage" do
          expect { subject.reload }.to change(subject, :rank).from(nil).to(person.rank)
        end

        it "should assign attributes the collections from the storage" do
          expect { subject.reload }.to change(subject, :duties).from([]).to(person.duties)
        end
      end
    end
  end

  describe "already persisted record" do
    let(:person) { PersistenceTestPerson.new }
    subject { person }
    before { person.save }

    it { should_not be_new_record }
    it { should be_persisted }

    describe "subject" do
      subject { person.subject }

      it { should be_a URI }
    end

    describe "destroy" do
      before { @another = PersistenceTestPerson.new; @another.save }

      it "should remove the record from the storage" do
        expect { subject.destroy }.to change(Kalimba.repository.statements, :size).by(-person.class.types.size)
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
