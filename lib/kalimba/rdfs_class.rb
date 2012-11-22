module Kalimba
  # RDFS "Class"
  #
  # @example
  #   module Human
  #     extend Kalimba::RDFSClass
  #     type "http://schema.org/Human"
  #   end
  module RDFSClass
    def included(klass)
      super
      if klass.is_a?(Class)
        properties.each do |name, _|
          klass.class_eval do
            define_attribute_method name
            define_method "#{name}=", lambda { |value| write_attribute name, value }
            define_method name, lambda { read_attribute name }
          end
        end
      end
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
      params[:datatype] = URI(params[:datatype])
      (@properties ||= {})[name.to_s] = params
    end

    # Collection definition
    #
    # @param (see #property)
    def has_many(name, params = {})
      property name, params.merge(:collection => true)
    end

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
end
