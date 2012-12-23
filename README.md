# Kalimba

Kalimba is an opinionated clone of ActiveRecord, based on ActiveModel framework.
Combined with the raw power of Redlander gem, it introduces the world of Ruby on Rails
to the world of RDF, triple storages, LinkedData and Semantic Web.
The resources of semantic graph storages become accessible in a customary form of "models".

## Installation

Add this line to your application's Gemfile:

    gem 'kalimba'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kalimba

> **NOTE**:<br/>
> You won't be able to do much without a backend to handle your RDF statements.
> Please add "kalimba-redlander" gem dependency to your Gemfile, and make sure
> to "require 'kalimba-redlander'" before invoking "require 'kalimba'".
> [Kalimba-redlander](https://github.com/cordawyn/kalimba-redlander) backend gem
> is developed independently and so should be other backends.

## Usage

Kalimba is opinionated in that it forces a certain application design pattern.
Basically, the steps of designing your Kalimba models are as follows:

1) define the base module(s), roughly corresponding to RDFS classes

    module RDFS::Human
      # declare the module as an RDFS class
      extend Kalimba::RDFSClass

      # define the type URI of the module
      type "http://schema.org/Human"

      # declare single properties with "property"
      property :name, :predicate => NS::FOAF["name"], :datatype => NS:XMLSchema["string"]
    end

    module RDFS::Engineer
      # declare the module as an RDFS class
      extend Kalimba::RDFSClass

      # define the type URI of the module
      type "http://schema.org/Engineer"

      # declare multiple properies of the same type with "has_many"
      has_many :duties, :predicate => NS::Work["duty"], :datatype => NS:XMLSchema["string"]
    end

    # your model must be inherited from Kalimba::Resource
    # and may include previously defined RDFS modules
    class Person < Kalimba::Resource
      # include your RDFS modules into the model
      include RDFS::Human
      include RDFS::Engineer

      type "http://schema.org/Person"

      # define base URI for the instances of this resource
      base_uri "http://example.org/people"
    end

> **NOTE**:<br/>
> "RDFS" prefix is optional, but you're advised to place your RDFS modules
> within a dedicated namespace, to be able to tell them from the common Ruby modules.

2) from this point on, you may treat your model just like
any fully-fledged clone of ActiveModel (i.e. ActiveRecord model)

    $ alice = Person.new(:name => "Alice")
    $ alice.valid?
    $ alice.save!
    ...

In short, inheriting from Kalimba::Resource facilitates ActiveRecord-like behaviour,
and including RDFS modules enables RDF features. If your model does not include any
RDFS modules (or does not define "type" and "base_uri" by itself), it will not be
able to "find its place" in the RDF storage and thus, perform any operations
requiring RDF storage "environment" (which are pretty much all operations).

In other words, there are 2 ways of creating Kalimba resources (or models, if you prefer),
as we differentiate between 2 types of resources: those that can have instances
(or Individuals, in OWL-speak) and those that cannot (consider them to be abstractions
that cannot have instances in the real world, used to build classifications and define
general behaviours).
Abstract resources are Ruby modules extended with `Kalimba::RDFSClass`,
instantiable resources are subclasses of `Kalimba::Resource`.

For other details refer to YARD documentation for Kalimba::RDFSClass module.

## Validations

For details, refer to ActionModel::Validations documentation.

    class Human < Kalimba::Resource
      base_uri "http://example.com/people/"
      property :name, :predicate => NS::FOAF["name"], :datatype => NS:XMLSchema["string"]

      validates_presence_of :name
    end

    $ bob = Human.create  # => bob will have an error on :name

## Callbacks

Kalimba supports :before, :after and :around callbacks for :save, :create, :update and
:destroy actions.

    class Human < Kalimba::Resource
      base_uri "http://example.com/people/"

      before_save :shout

      private

      def shout
        puts "Hey!"
      end
    end

For details, refer to ActionModel::Callbacks documentation.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request