require "active_support/core_ext/class/attribute"
require "active_support/core_ext/class/subclasses"
require "kalimba/persistence" # fallback to abstract backend
require "kalimba/validations"
require "kalimba/callbacks"
require "kalimba/reflection"
require "kalimba/attribute_assignment"
require "kalimba/localized_attributes"

module Kalimba
  class Resource
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    include ActiveModel::Conversion

    extend Kalimba::Reflection
    include Kalimba::AttributeAssignment
    include Kalimba::LocalizedAttributes

    include Kalimba::Persistence.backend

    # Subject URI if the resource
    attr_reader :subject

    # Hash{String => any} with the resource attributes
    #
    # @note
    #   Do not modify it directly, unless you know what you are doing!
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
      #   because any arbitrary subject that you specify might be already present
      #   in the storage.
      #   So you can use ID of an existing resource as well.
      #
      #   Don't forget to {#reload} the resource, if you need its actual attributes
      #   (if any) pulled from the storage.
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

      # Property declaration
      #
      # Model attributes should be declared using `property`.
      # Two mandatory parameters are `:predicate` and `:datatype`,
      # that can accept URIs as URI or String objects.
      # You can also use "NS::" namespaces provided by `xml_schema` gem.
      #
      # @param [Symbol, String] name
      # @param [Hash] params
      # @option params [String, URI] :predicate
      # @option params [String, URI, Symbol] :datatype
      # @option params [Boolean] :collection
      # @return [void]
      def property(name, params = {})
        name = name.to_s

        params[:predicate] = URI(params[:predicate])
        association = Kalimba::Resource.from_datatype(params[:datatype])
        if association
          params[:datatype] = association.type
          class_eval <<-HERE, __FILE__, __LINE__
            def #{name}_id
              self.#{name}.try(:id)
            end

            def #{name}_id=(value)
              self.#{name} = value.blank? ? nil : #{association}.for(value)
            end
          HERE
        else
          params[:datatype] = URI(params[:datatype])
        end

        define_collection(name, params) if params[:collection]

        self.properties[name] = params

        define_attribute_method name if self.is_a?(Class)

        class_eval <<-HERE, __FILE__, __LINE__
          def #{name}=(value)
            write_attribute "#{name}", value
          end
        HERE

        if localizable_property?(name)
          class_eval <<-HERE, __FILE__, __LINE__
            def localized_#{name.pluralize}
              @localized_#{name.pluralize} ||= {}
            end
          HERE
        end
      end

      # Collection definition
      #
      # "Has-many" relations/collections are declared with help of `has_many` method.
      # It accepts the same parameters as `property` (basically, it is an alias to
      # `property name, ..., collection: true`).
      # Additionally, you can specify `:datatype` as a name of another model,
      # as seen below. If you specify datatype as an URI, it will be automatically
      # resolved to either a model (having the same `type`) or anonymous class.
      #
      # @example
      #   has_many :friends, :predicate => "http://schema.org/Person", :datatype => :Person
      #
      # You don't have to treat `has_many` as an association with other models, however.
      # It is acceptable to declare a collection of strings or any other resources
      # using `has_many`:
      #
      # @example
      #   has_many :duties, :predicate => "http://works.com#duty", :datatype => NS::XMLSchema["string"]
      #
      # @param (see #property)
      def has_many(name, params = {})
        property name, params.merge(:collection => true)
      end

      # Return Kalimba resource class associated with the given datatype
      #
      # @param [String, URI, Symbol] uri
      # @return [Kalimba::Resource]
      def from_datatype(datatype)
        datatype =
          case datatype
          when URI
            datatype
          when Symbol
            const_get(datatype).type
          when String
            if datatype =~ URI.regexp
              URI(datatype)
            else
              const_get(datatype).type
            end
          else
            if datatype.respond_to?(:uri)
              datatype.uri
            else
              raise KalimbaError, "invalid datatype identifier"
            end
          end
        Kalimba::Resource.descendants.detect {|a| a.type == datatype }
      end


      private

      def inherited(child)
        super
        child.properties = properties.dup
      end

      def define_collection(name, params)
        # Rails reflections require symbolized names
        create_reflection(name.to_sym, params)

        class_eval <<-HERE, __FILE__, __LINE__
          def #{name.singularize}_ids
            self.#{name}.map(&:id)
          end

          def #{name.singularize}_ids=(ids)
            klass = self.class.reflect_on_association(:#{name}).klass
            self.#{name} = ids.reject(&:blank?).map {|i| klass.for(i) }
          end
        HERE
      end
    end

    # Create a new record
    #
    # If given a block, yields the created object into it.
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
