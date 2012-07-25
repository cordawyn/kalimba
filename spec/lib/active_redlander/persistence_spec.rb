require "spec_helper"

describe ActiveRedlander::Persistence do
  before :all do
    class PersistenceTestPerson
      include Engineer
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
    end

    describe "return value of #save" do
      subject { person.save }

      it { should be_true }
    end

    context "with changes" do
      context "to single values" do
        before { person.rank = 1 }

        context "when saved" do
          before { subject.save }

          it "should be added statements with changed attributes" do
            expect(subject.class.repository.statements.size).to eql 2
          end
        end
      end

      context "to collections" do
        before { person.duties = %w(building designing) }

        context "when saved" do
          before { person.save }

          it "should be added statements with changed attributes" do
            expect(subject.class.repository.statements.size).to eql 3
          end
        end
      end
    end
  end

  describe "already persisted record" do
    let(:person) { PersistenceTestPerson.new.tap {|person| person.save } }
    subject { person }

    it { should_not be_new_record }
    it { should be_persisted }

    describe "subject" do
      subject { person.subject }

      it { should be_a URI }
    end
  end
end
