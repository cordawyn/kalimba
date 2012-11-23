require "spec_helper"

describe "callbacks" do
  before :all do
    class CallbacksTestPerson < Kalimba::Resource
      attr_accessor :triggers

      include Human

      base_uri "http://example.com/people/"

      before_create  :trigger_1
      before_update  :trigger_2
      before_save    :trigger_3
      before_destroy :trigger_4

      def initialize(*args)
        @triggers = []
        super
      end

      private

      def trigger_1
        @triggers << 1
      end

      def trigger_2
        @triggers << 2
      end

      def trigger_3
        @triggers << 3
      end

      def trigger_4
        @triggers << 4
      end
    end
  end

  let(:person) { CallbacksTestPerson.create }

  context "when creating a resource" do
    it "should trigger 2 callbacks" do
      expect(person.triggers.size).to eql 2
    end

    it "before_create callback should be triggered" do
      expect(person.triggers).to include 1
    end

    it "before_save callback should be triggered" do
      expect(person.triggers).to include 3
    end
  end

  context "when destroying a resource" do
    before do
      person.triggers = []
      person.destroy
    end

    it "should trigger 1 callback" do
      expect(person.triggers.size).to eql 1
    end

    it "before_destroy callback should be triggered" do
      expect(person.triggers).to include 4
    end
  end

  context "when updating a resource" do
    before do
      person.triggers = []
      person.update_attributes(name: "Vasya")
    end

    it "should trigger 2 callbacks" do
      expect(person.triggers.size).to eql 2
    end

    it "before_update callback should be triggered" do
      expect(person.triggers).to include 2
    end

    it "before_save callback should be triggered" do
      expect(person.triggers).to include 3
    end
  end
end
