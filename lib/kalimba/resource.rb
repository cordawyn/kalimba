require "kalimba/validations"
require "kalimba/callbacks"

module Kalimba
  class Resource
    extend Kalimba::RDFSClass

    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    include ActiveModel::Conversion

    include Kalimba::Persistence.backend

    attr_reader :subject
    attr_accessor :attributes

    class << self
      # Create a new record with the given subject URI
      #
      # @note
      #   In the world of RDF a resource cannot be instantly defined as "new",
      #   because any arbitrary subject you define might be already present
      #   in the storage (see: "Open World Assumption").
      #   So you can supply an ID of an existing resource.
      #   Don't forget to {#reload} it, if you need its actual attributes
      #   instantiated as well.
      #
      # @note
      #   The resource ID that you supply will be added as an URI
      #   fragment to base_uri (or raise an error if base_uri is not defined).
      #
      # @param [String] rid ID to use for the resource
      # @param [Hash<[Symbol, String] => Any>] params (see {RDFSResource#initialize})
      # @return [Object] instance of the model
      def for(rid, params = {})
        new(params.merge(:_subject => rid))
      end
    end

    # Create a new record
    #
    # @param [Hash<[Symbol, String] => Any>] params properties to assign
    def initialize(params = {}, options = {})
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
        value = options[:collection] ? [] : nil
        attrs.merge(name => value)
      end
      assign_attributes(params, options)

      @destroyed = false

      yield self if block_given?
    end

    # Assign attributes from the given hash
    #
    # @param [Hash<[Symbol, String] => Any>] params
    # @param [Hash] options
    # @return [void]
    def assign_attributes(params = {}, options = {})
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

    include Kalimba::Validations
    include Kalimba::Callbacks
  end
end
