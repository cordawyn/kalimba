# TODO: make it possible to choose a backend
# (e.g., Redland, RDF.rb, others)
require "active_redlander/persistence/redlander"

module ActiveRedlander
  module Persistence
    class << self
      def create_repository(options = {})
        super
      end
    end

    def read_attribute(name)
      super
    end

    def write_attribute(name, value)
      super
    end

    def reload
      super
    end

    # TODO: make it possible to choose a backend
    # (e.g., Redland, RDF.rb, others)
    include ActiveRedlander::Persistence::Redlander
  end
end
