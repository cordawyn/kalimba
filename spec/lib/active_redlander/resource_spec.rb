require "spec_helper"

describe ActiveRedlander::Resource do
  before :all do
    module Human
      extend ActiveRedlander::Resource
      type "http://schema.org/Human"
      property :name, :predicate => "http://xmlns.com/foaf/0.1#name", :datatype => NS::XMLSchema["string"]
    end

    module Engineer
      extend ActiveRedlander::Resource
      type "http://schema.org/Engineer"
      property :rank, :predicate => "http://works.com#rank", :datatype => NS::XMLSchema["int"]
      has_many :duties, :predicate => "http://works.com#duty", :datatype => NS::XMLSchema["string"]
    end

    class Person
      include Human
      include Engineer
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
      it { should include URI("http://schema.org/Engineer") }
    end

    describe "instance" do
      subject { Person.new }

      it { should respond_to :name }
      it { should respond_to :name= }
      it { should respond_to :rank }
      it { should respond_to :rank= }
      it { should respond_to :duties }
      it { should respond_to :duties= }

      it { should respond_to :attributes }

      describe "attributes" do
        let(:person) { Person.new }
        subject { person.attributes }

        it { should be_a Hash }
      end
    end
  end
end
