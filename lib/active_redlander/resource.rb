require "uri"
require "active_redlander/persistence"

module ActiveRedlander
  # Resource declaration module
  #
  # @example
  #   module RDFS::Human
  #     extend ActiveRedlander::Resource
  #     type "http://schema.org/Human"
  #   end
  module Resource
    private

    def self.extended(base)
      base.module_eval do
        class << self
          attr_reader :properties
        end
        @properties = {}

        extend ModuleMethods

        private

        def self.included(rdf_resource)
          rdf_resource.class_eval do
            extend ModelClassMethods
            include ModelInstanceMethods
            include ActiveModel::AttributeMethods
            include ActiveModel::Dirty
          end

          rdf_resource.instance_variable_set :@repository_id, @repository_id

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
      # @return [URI]
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
        params[:predicate] = URI(params[:predicate])
        params[:datatype] = URI(params[:datatype])
        @properties[name.to_s] = params
      end

      # Collection definition
      #
      # @param (see #property)
      def has_many(name, params = {})
        property name, params.merge(:collection => true)
      end
    end

    module ModelClassMethods
      # Set ID of the repository used by this RDFS class
      #
      # @param [String] rid
      # @return [void]
      def use_repository(rid)
        @repository_id = rid
      end

      # Instance of the repository used by this RDFS class
      #
      # @return [Any]
      def repository
        rid = @repository_id || :default
        ActiveRedlander.repositories[rid]
      end

      # Base URI for the resource
      #
      # @param [String, URI] uri
      # @return [URI]
      def base_uri(uri = nil)
        @base_uri ||= uri && URI(uri)
      end

      # RDFS types that this model inherits
      #
      # @return [Set<URI>]
      def types
        # TODO: handle type clashes!
        rdfs_ancestors.inject(Set.new) {|ts, parent| ts << parent.type }
      end

      # Properties with their options
      #
      # @return [Hash{String => Hash}]
      def properties
        # TODO: handle property name clashes!
        rdfs_ancestors.inject({}) { |ps, parent| ps.merge(parent.properties) }
      end

      private

      def rdfs_ancestors
        ancestors.select { |a| a.respond_to?(:type) }
      end
    end

    module ModelInstanceMethods
      include Persistence

      attr_reader :subject
      attr_accessor :attributes

      def initialize(properties = {})
        @subject = URI(properties[:_subject]) if properties[:_subject]
        @attributes = {}
      end

      private

      def read_attribute(name)
        attributes[name]
      end

      def write_attribute(name, value)
        attribute_will_change!(name) unless value == attributes[name]
        attributes[name] = value
      end
    end
  end
end
