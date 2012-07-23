require "uri"

module ActiveRedlander
  module Resource
    private

    def self.extended(base)
      base.module_eval do
        @properties = {}

        extend ModuleMethods

        private

        def self.included(rdf_resource)
          rdf_resource.class_eval do
            extend ModelClassMethods
            include ActiveModel::AttributeMethods
            include ModelInstanceMethods
          end

          @properties.each do |name, params|
            rdf_resource.send :define_attribute_method, name
            rdf_resource.send :define_method, "#{name}=", lambda { |value| write_attribute name, value }
            rdf_resource.send :define_method, name, lambda { read_attribute name }
          end

          super
        end
      end
      super
    end

    module ModuleMethods
      # Type URI of RDFS class
      #
      # @note Can be set only once
      #
      # @param [URI, String] uri
      # @return [void]
      def type(uri = nil)
        if uri
          @type ||= uri.is_a?(URI) ? uri : URI(uri)
        else
          @type
        end
      end

      # Property definition
      #
      # @param [Symbol, String] name
      # @param [Hash] params
      # @option params [String, URI] :predicate
      # @option params [String, URI] :datatype
      # @return [void]
      def property(name, params = {})
        @properties[name] = params
      end

      def has_many(name, params = {})
        # TODO
        property name, params
      end
    end

    module ModelClassMethods
      # RDFS types that this model inherits
      #
      # @return [Set]
      def types
        ancestors.inject(Set.new) do |ts, parent|
          parent.respond_to?(:type) ? ts.add(parent.type) : ts
        end
      end
    end

    module ModelInstanceMethods
      attr_accessor :attributes

      def initialize(properties = {})
        @attributes = {}
      end

      def read_attribute(name)
        # TODO
      end

      def write_attribute(name, value)
        # TODO
      end
    end
  end
end
