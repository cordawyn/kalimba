require "kalimba/persistence"

# TODO: move all stuff (instance methods) to RDFSClass?

module Kalimba
  class Resource
    include Persistence

    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    include ActiveModel::Conversion

    attr_reader :subject
    attr_accessor :attributes

    # Create a new record
    #
    # @param [Hash<[Symbol, String] => Any>] params properties to assign
    def initialize(params = {})
      params = params.stringify_keys
      if params["_subject"]
        if self.class.base_uri
          @subject = self.class.base_uri.dup
          @subject.fragment = params.delete("_subject")
        else
          raise KalimbaError, "Cannot assign an ID to a resource without base_uri"
        end
      end
      @attributes = self.class.properties.inject({}) do |attrs, (name, options)|
        value = if params[name]
                  params[name]
                else
                  options[:collection] ? [] : nil
                end
        attrs.merge(name => value)
      end
      @destroyed = false
    end

    # Assign attributes from the given hash
    #
    # @param [Hash<[Symbol, String] => Any>] params
    # @return [void]
    def assign_attributes(params = {})
      params.each { |name, value| send("#{name}=", value) }
    end

    # Freeze the attributes hash such that associations are still accessible,
    # even on destroyed records
    #
    # @return [self]
    def freeze
      @attributes.freeze; self
    end

    # Checks whether the attributes hash has been frozen
    #
    # @return [Boolean]
    def frozen?
      @attributes.frozen?
    end

    # RDF representation of the model
    #
    # @return [URI, nil] subject URI
    def to_rdf
      subject
    end

    private

    def read_attribute(name)
      value = attributes[name]
      if value
        value
      else
        self.class.properties[name][:collection] ? [] : nil
      end
    end

    def write_attribute(name, value)
      attribute_will_change!(name) unless value == attributes[name]
      attributes[name] = value
    end
  end
end
