require "active_support/core_ext/class/attribute"
require "active_support/core_ext/class/subclasses"
require "kalimba/persistence" # fallback to abstract backend
require "kalimba/validations"
require "kalimba/callbacks"
require "kalimba/reflection"

module Kalimba
  class Resource
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    include ActiveModel::Conversion

    extend Kalimba::Reflection

    include Kalimba::Persistence.backend

    attr_reader :subject
    attr_accessor :attributes

    # Properties with their options
    #
    # @return [Hash{String => Hash}]
    class_attribute :properties, instance_writer: false, instance_reader: false
    self.properties = {}

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

      # Type URI of RDFS class
      #
      # @note Can be set only once
      #
      # @param [URI, String] uri
      # @return [URI]
      def type(uri = nil)
        if uri
          @type ||= URI(uri)
        else
          @type
        end
      end

      # Base URI for the resource
      #
      # @param [String, URI] uri
      # @return [URI]
      def base_uri(uri = nil)
        @base_uri ||= uri && URI(uri.to_s.sub(/\/?$/, "/"))
      end

      # Property definition
      #
      # @param [Symbol, String] name
      # @param [Hash] params
      # @option params [String, URI] :predicate
      # @option params [String, URI] :datatype
      # @return [void]
      def property(name, params = {})
        params[:predicate] = URI(params[:predicate])
        if params[:datatype].is_a?(Symbol)
          association_class = const_get(params[:datatype])
          params[:datatype] = association_class.type
          class_eval <<-HERE, __FILE__, __LINE__
            def #{name}_id
              self.#{name}.try(:id)
            end

            def #{name}_id=(value)
              self.#{name} = value.blank? ? nil : #{association_class}.for(value)
            end
          HERE
        else
          params[:datatype] = URI(params[:datatype])
        end
        properties[name.to_s] = params

        define_attribute_method name if self.is_a?(Class)

        class_eval <<-HERE, __FILE__, __LINE__
          def #{name}=(value)
            write_attribute "#{name}", value
          end
        HERE
      end

      # Collection definition
      #
      # @param (see #property)
      def has_many(name, params = {})
        create_reflection(name, params)
        property name, params.merge(:collection => true)

        class_eval <<-HERE, __FILE__, __LINE__
          def #{name.to_s.singularize}_ids
            self.#{name}.map(&:id)
          end

          def #{name.to_s.singularize}_ids=(ids)
            klass = self.class.reflect_on_association(:#{name}).klass
            self.#{name} = ids.reject(&:blank?).map {|i| klass.for(i) }
          end
        HERE
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

    include Kalimba::Callbacks
    include Kalimba::Validations
  end
end
