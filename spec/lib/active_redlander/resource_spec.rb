require "spec_helper"

describe ActiveRedlander::Resource do
  before :all do
    module Person
      include ActiveRedlander::Resource
      type "http://schema.org/Person"
    end

    class TestResource
      extend Person
    end
  end

  subject { Person }

  it { should respond_to :type }

  describe "extended class" do
    subject { TestResource }

    it { should_not respond_to :type }

    it { should respond_to :types }

    describe "types" do
      subject { TestResource.types }

      it { should be_a Set }

      it { should include URI("http://schema.org/Person") }
    end
  end
end
