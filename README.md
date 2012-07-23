# ActiveRedlander

ActiveRedlander is an opinionated clone of ActiveRecord, based on ActiveModel framework.
Combined with the raw power of Redlander gem, it introduces the world of Ruby on Rails
to the world of RDF, triple storages, LinkedData and Semantic Web.
The resources of semantic graph storages become accessible in a customary form of "models".

## Installation

Add this line to your application's Gemfile:

    gem 'active_redlander'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_redlander

## Usage

ActiveRedlander is opinionated in that it forces a certain application development,
or rather, design pattern. Basically, the steps of designing your ActiveRedlander "model"
are as follows:

  1) define the base module(s), roughly corresponding to RDFS classes

    module RDFS::Human
      # declare the module as an RDFS class
      include ActiveRedlander::Resource

      # define the type URI of the module
      type "http://schema.org/Person"

      # declare single properties with "property"
      property :name, :predicate => NS::FOAF["name"], :datatype => NS:XMLSchema["string"]
    end

    module RDFS::Engineer
      # declare multiple properies of the same type with "has_many"
      has_many :duties, :predicate => NS::Work["duty"], :datatype => NS:XMLSchema["string"]
    end

  Note: "RDFS" prefix is optional, but you're advised to place your RDFS classes
  within a dedicated namespace, to be able to tell them from the common Ruby modules.

  2) define your ActiveRedlander model

    class Person
      # extend your model with your RDFS classes
      extend RDFS::Human
      extend RDFS::Engineer # your model may inherit multiple RDFS classes
    end

  3) from this point on, you may treat your ActiveRedlander model just like
     any full-fledged clone of ActiveModel (i.e. ActiveRecord)

    $ alice = Person.new(:name => "Alice")
    $ alice.valid?
    $ alice.save!
    ...

For details refer to YARD documentation for ActiveRedlander::Resource module.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
