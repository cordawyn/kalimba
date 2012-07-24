require "securerandom"

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

    def new_record?
      super
    end

    def store_attribute(name)
      super
    end

    # Retrieve resource attributes from the backend storage
    #
    # @return [void]
    def reload
      super
    end

    def save
      generate_subject if new_record?
      super
      @previously_changed = changes
      @changed_attributes.clear
    end

    def generate_subject
      super
      unless @subject
        if self.class.base_uri
          @subject = self.class.base_uri.merge("##{SecureRandom.urlsafe_base64}")
        else
          raise ActiveRedlander::ActiveRedlanderError, "Cannot generate subject without base URI for #{self.class}"
        end
      end
    end
    private :generate_subject

    # TODO: make it possible to choose a backend
    # (e.g., Redland, RDF.rb, others)
    include ActiveRedlander::Persistence::Redlander
  end
end
