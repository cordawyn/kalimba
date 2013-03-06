# Kalimba

Kalimba is an clone of ActiveRecord, based on ActiveModel framework.
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

## Backends

You won't be able to do much without a backend to handle your RDF statements.
Please add "kalimba-redlander" gem dependency to your Gemfile, and make sure
to "require 'kalimba-redlander'" before invoking "require 'kalimba'".

For now, the backends are developed as a part of Kalimba gem for convenience.
However, you are free to develop your own backend as a separate gem.

### Kalimba::Persistence::Redlander

Redlander adapter for [Kalimba](https://github.com/cordawyn/kalimba). It provides the RDF storage backend for Kalimba.


## Usage

Your model must be inherited from Kalimba::Resource:

    class Person < Kalimba::Resource
      # Note that type is *not* inherited,
      # it must be explicitly declared for every subclass.
      # And types better be unique!
      type "http://schema.org/Person"

      # Define base URI for the instances of this resource
      base_uri "http://example.org/people"
    end

From this point on, you may treat your model just like
any fully-fledged clone of ActiveModel (i.e. ActiveRecord model)

    $ alice = Person.new(:name => "Alice")
    $ alice.valid?
    $ alice.save!
    ...

For other details refer to YARD documentation for Kalimba::Resource module.

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
