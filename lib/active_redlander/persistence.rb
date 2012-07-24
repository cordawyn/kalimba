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

    def save
      @previously_changed = changes
      @changed_attributes.clear
    end

    # TODO: make it possible to choose a backend
    # (e.g., Redland, RDF.rb, others)
    include ActiveRedlander::Persistence::Redlander
  end
end
