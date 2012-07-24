require "spec_helper"

describe ActiveRedlander::Persistence do
  before :all do
    class PersistenceTestPerson
      include Engineer
      base_uri "http://example.org/people"
    end
  end

  let(:person) { PersistenceTestPerson.new }
  subject { PersistenceTestPerson.repository.statements }

  context "with changes" do
    before { person.rank = 1 }

    context "when saved" do
      before { person.save }

      it "should be added statements with changed attributes" do
        expect(subject.size).to eql 2
      end
    end
  end
end
