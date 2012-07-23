require "spec_helper"

describe ActiveRedlander::Resource do
  before :all do
    module Human
      include ActiveRedlander::Resource
      type "http://schema.org/Human"
    end

    class Person
      extend Human
    end
  end

  subject { Human }

  it { should respond_to :type }

  describe "extended class" do
    subject { Person }

    it { should_not respond_to :type }

    it { should respond_to :types }

    describe "types" do
      subject { Person.types }

      it { should be_a Set }

      it { should include URI("http://schema.org/Human") }
    end
  end
end
