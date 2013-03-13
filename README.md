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

      property :name, :predicate => NS::FOAF["name"], :datatype => NS:XMLSchema["string"]

      has_many :friends, :predicate => "http://schema.org/Person", :datatype => :Person
    end

From this point on, you may treat your model just like
any fully-fledged clone of ActiveModel (i.e. ActiveRecord model)

    $ alice = Person.new(:name => "Alice")
    $ alice.valid?
    $ alice.save!
    ...
    $ alice.friends << bob

> Note that Kalimba associations are not fully API-compliant with ActiveRecord associations (yet?).
> One major feature missing is "association proxy" which would enable tricks like
> `alice.friends.destroy_all`. Presently, Kalimba "associations" return a simple collection (Array).

For other details refer to YARD documentation for Kalimba::Resource module.


## Regarding RDFS/OWL features

It should be also noted that "special" features of RDFS/OWL like inverse properties or
transitive properties and so on, are *not* specifically handled by Kalimba (or Redlander backend).
Availability of any "virtual" data which is supposed to be available as a product of reasoning,
is up to the graph storage that you use with the *backend*.

So (provided that "hasFriend" is "owl:inverseOf" "isFriendOf") you may end with something like this:

    alice.has_friend  # => bob
    bob.is_friend_of  # => nil

... unless your graph storage provides reasoning by default.

That said, certain graph storages that are said to have reasoning capabilities,
do not have reasoning enabled by default (e.g. [Virtuoso](http://virtuoso.openlinksw.com/)),
and require that you explicitly enable it using special options or a custom SPARQL syntax.
While it is possible to "hack" and modify the options or SPARQL queries that are generated
by Kalimba (or its backend), this is not currently available.


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
