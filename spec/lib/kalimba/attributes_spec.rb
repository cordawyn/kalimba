require "spec_helper"

describe "attribute handling" do
  before :all do
    class AttributeTestOilRig < Kalimba::Resource
      type "http://schema.org/OilRig"
      base_uri "http://example.org/oil_rigs"

      has_many :neighbours, :predicate => "http://example.org/attribute_test_oil_rigs", :datatype => :AttributeTestOilRig
      property :safe, :predicate => "http://example.org/safe", :datatype => NS::XMLSchema["boolean"]
      property :name, :predicate => "http://example.org/name", :datatype => NS::XMLSchema["string"]
      property :local_time, :predicate => "http://example.org/time", :datatype => NS::XMLSchema["time"]
      property :created_at, :predicate => "http://example.org/date", :datatype => NS::XMLSchema["date"]
    end
  end

  let(:rig) { AttributeTestOilRig.for("bp1") }

  describe "boolean value" do
    subject { rig.safe }

    context "when not set" do
      it { should be_a NilClass }
    end

    context "when set to 'false'" do
      before { rig.safe = false }

      it { should be_a FalseClass }
    end
  end

  describe "localized string" do
    before do
      # populate the storage with literals in different locales
      { en: "Quarter Pounder with Cheese",
        fr: "Le Big Mac" }.each do |lang, text|
        Kalimba.repository.statements.create(subject: rig.subject,
                                             predicate: rig.class.properties["name"][:predicate],
                                             object: text.with_lang(lang))
      end
    end

    subject { rig.name }

    context "when retrieved" do
      describe "string language" do
        subject { rig.name.lang }

        context "in :fr locale" do
          around do |example|
            I18n.with_locale(:fr) { example.call }
          end

          it { should eql :fr }
        end

        context "in :en locale" do
          around do |example|
            I18n.with_locale(:en) { example.call }
          end

          it { should eql :en }
        end
      end
    end

    context "when stored" do
      it "should not be overwritten by a localized string in another language" do
        rig.update_attributes(name: "Burger")

        s1 = Redlander::Statement.new(subject: rig.subject,
                                      predicate: rig.class.properties["name"][:predicate],
                                      object: "Quarter Pounder with Cheese".with_lang(:en))
        s2 = Redlander::Statement.new(subject: rig.subject,
                                      predicate: rig.class.properties["name"][:predicate],
                                      object: "Le Big Mac".with_lang(:fr))
        s3 = Redlander::Statement.new(subject: rig.subject,
                                      predicate: rig.class.properties["name"][:predicate],
                                      object: "Burger")

        Kalimba.repository.statements.to_a.should include s1
        Kalimba.repository.statements.to_a.should include s2
        Kalimba.repository.statements.to_a.should include s3
      end
    end
  end

  describe "multiparameter attribute" do
    describe "localized string" do
      subject { rig.name }

      context "when assigned" do
        before { rig.assign_attributes("name(1)" => "Oil Rig", "name(2)" => "en") }

        it { should be_a LocalizedString }
        it { should eql "Oil Rig" }
        it "should have language set to 'en'" do
          expect(rig.name.lang).to eql "en"
        end
      end
    end

    describe "time" do
      subject { rig.local_time }

      context "when assigned from two parameters" do
        before do
          rig.assign_attributes("local_time(1)" => "2013-03-08",
                                "local_time(2)" => "18:14")
        end

        it { should be_a Time }
        it { should eql Time.new(2013, 3, 8, 18, 14) }
      end

      context "when assigned from many parameters" do
        before do
          rig.assign_attributes("local_time(1i)" => "2013",
                                "local_time(2i)" => "03",
                                "local_time(3i)" => "08",
                                "local_time(4i)" => "18",
                                "local_time(5i)" => "14")
        end

        it { should be_a Time }
        it { should eql Time.new(2013, 3, 8, 18, 14) }
      end
    end

    describe "date" do
      subject { rig.created_at }

      context "when assigned" do
        before do
          rig.assign_attributes("created_at(1i)" => "2013",
                                "created_at(2i)" => "03",
                                "created_at(3i)" => "08")
        end

        it { should be_a Date }
        it { should eql Date.new(2013, 3, 8) }
      end
    end
  end

  describe "collection" do
    subject { rig.neighbours }

    context "when changed in-place" do
      before { rig.neighbours << AttributeTestOilRig.new }

      it "should be marked as changed" do
        expect(rig.neighbours_changed?).to be_true
      end
    end
  end
end
