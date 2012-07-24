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

    # TODO: make it possible to choose a backend
    # (e.g., Redland, RDF.rb, others)
    include ActiveRedlander::Persistence::Redlander
  end
end
