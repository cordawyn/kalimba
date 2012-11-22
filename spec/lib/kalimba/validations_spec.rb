require "spec_helper"

describe "validations" do
  before :all do
    class ValidationsTestPerson < Kalimba::Resource
      include Human

      validates_presence_of :name
    end
  end

  let(:person) { ValidationsTestPerson.create }

  describe "validates_presence_of" do
    it "should add an error on :name" do
      expect(person).to have(1).errors_on(:name)
    end
  end
end
