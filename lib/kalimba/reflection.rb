# Enables "association-like" behaviour that many
# Rails-dependent gems rely upon.
#
# The content is mostly copied from ActiveRecord::Reflection
#
module Kalimba
  module Reflection
    def reflections
      @reflections ||= {}
    end

    def create_reflection(name, params = {})
      reflections[name] = AssociationReflection.new(name, {class_name: params[:datatype]})
    end

    def reflect_on_association(association)
      reflections[association].is_a?(AssociationReflection) ? reflections[association] : nil
    end

    class AssociationReflection
      attr_reader :macro, :name, :options

      def initialize(name, options = {})
        # only :has_many macro is available for RDF
        # (Sets, Bags and Unions are thus "downgraded" to it)
        @macro = :has_many
        @name = name
        @options = options
      end

      # Returns the class for the macro.
      #
      # <tt>composed_of :balance, :class_name => 'Money'</tt> returns the Money class
      # <tt>has_many :clients</tt> returns the Client class
      def klass
        @klass ||= class_name.constantize
      end

      # Returns the class name for the macro.
      #
      # <tt>composed_of :balance, :class_name => 'Money'</tt> returns <tt>'Money'</tt>
      # <tt>has_many :clients</tt> returns <tt>'Client'</tt>
      def class_name
        @class_name ||= (options[:class_name] || derive_class_name).to_s
      end

      private

      def derive_class_name
        name.to_s.singularize.camelize
      end
    end
  end
end
