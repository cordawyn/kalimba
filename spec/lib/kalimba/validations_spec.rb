require "spec_helper"

describe "validations" do
  before :all do
    class ValidationsTestPerson < Human
      validates_presence_of :name
    end
  end

  let(:person) { ValidationsTestPerson.create }

  describe "validates_presence_of" do
    it "should add an error on :name" do
      expect(person).to have(1).errors_on(:name)
    end

    context "given non-blank :name attribute" do
      before { person.name = "Alan" }

      it "should have no errors on :name" do
        expect(person).to have(:no).errors_on(:name)
      end
    end
  end
end
