require "uri"

module ActiveRedlander
  module Resource
    def self.included(base)
      base.module_eval do
        def self.extended(rdf_resource)
          setup(rdf_resource)
          super
        end

        def self.type(uri)
          @type ||= uri.is_a?(URI) ? uri : URI(uri)
        end


        private

        def self.setup(rdf_resource)
          unless rdf_resource.respond_to? :types
            rdf_resource.class_eval do
              class << self
                attr_reader :types
              end
            end
          end
          unless rdf_resource.instance_variables.include?(:@types)
            rdf_resource.instance_variable_set(:@types, Set.new)
          end
          rdf_resource.instance_variable_get(:@types) << @type
        end
      end
      super
    end
  end
end
