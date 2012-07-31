require "kalimba/resource"

module Kalimba
  module ResourceClassMethods
    # RDFS types that this model inherits
    #
    # @return [Set<URI>]
    def types
      # TODO: handle type clashes!
      rdfs_ancestors.inject(Set.new([type])) {|ts, parent| ts << parent.type }.delete(nil)
    end

    # Properties with their options
    #
    # @return [Hash{String => Hash}]
    def properties
      # TODO: handle property name clashes!
      rdfs_ancestors.inject({}) { |ps, parent| parent == self ? ps : ps.merge(parent.properties) }.merge(@properties || {})
    end

    def rdfs_ancestors
      ancestors.select { |a| a.respond_to?(:type) }
    end
  end

  module RDFSClassMethods
    include ResourceClassMethods

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
      params[:datatype] = URI(params[:datatype])
      (@properties ||= {})[name.to_s] = params
    end

    # Collection definition
    #
    # @param (see #property)
    def has_many(name, params = {})
      property name, params.merge(:collection => true)
    end

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

    def new(params = {})
      klass = Class.new(Resource)
      klass.class_eval <<-HERE
        extend ResourceClassMethods
        include #{self}
        def self.type
          @type ||= URI(\"#{type}\")
        end
        def self.base_uri
          @base_uri ||= URI(\"#{base_uri}\")
        end
      HERE
      properties.each_key do |name|
        klass.send :define_attribute_method, name
        klass.send :define_method, "#{name}=", lambda { |value| write_attribute name, value }
        klass.send :define_method, name, lambda { read_attribute name }
      end
      klass.new(params)
    end
  end

  # Resource declaration module
  #
  # @example
  #   module Human
  #     extend Kalimba::RDFSResource
  #     type "http://schema.org/Human"
  #   end
  module RDFSClass
    extend RDFSClassMethods

    private

    def self.extended(base)
      base.send :extend, RDFSClassMethods
      base.send :extend, Persistence::ClassMethods
    end
  end
end