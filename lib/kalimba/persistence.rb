require "securerandom"
require "active_support/concern"

module Kalimba
  # @abstract
  #   Backend implementations should override all methods
  #   that delegate processing to their parent class (invoking "super").
  module Persistence
    extend ActiveSupport::Concern

    class << self
      # Create an instance of the backend storage (repository)
      #
      # @param [Hash] options backend storage options
      # @return [Any] instance of the backend storage
      def repository(options = {})
        raise NotImplementedError
      end

      # Module of the persistence backend
      #
      # @return [Module]
      def backend
        self
      end

      def logger
        @logger ||= defined?(::Rails) && ::Rails.logger
      end
    end

    module ClassMethods
      # Create a new instance of RDFS class
      #
      # @param [Hash<Symbol, String> => Any] attributes
      # @return [Resource, nil]
      def create(attributes = {})
        raise NotImplementedError
      end

      # Check whether instances of the RDFS class exist in the repository
      #
      # @param [Hash<[Symbol, String] => Any>] attributes
      # @return [Boolean]
      def exist?(attributes = {})
        raise NotImplementedError
      end

      # Remove all instances of the RDFSClass from the repository
      #
      # @return [Boolean]
      def destroy_all
        raise NotImplementedError
      end

      def find(scope, options = {})
        case scope
        when :first
          find_each(options.merge(:limit => 1)).first
        when :all
          find_each(options).to_a
        else
          find_by_id(scope)
        end
      end

      def find_by_id(id_value)
        raise NotImplementedError
      end

      def find_each(options = {})
        raise NotImplementedError
      end

      def first(options = {})
        find(:first, options)
      end

      def all(options = {})
        find(:all, options)
      end

      def count(attributes = {})
        raise NotImplementedError
      end

      def logger
        Kalimba::Persistence.logger
      end
    end

    def id
      subject && subject.fragment
    end

    # Check whether the model has never been persisted
    #
    # @return [Boolean]
    def new_record?
      raise NotImplementedError
    end

    # Check whether the model has ever been persisted
    #
    # @return [Boolean]
    def persisted?
      raise NotImplementedError
    end

    # Check whether the model has been destroyed
    # (remove from the storage)
    #
    # @return [Boolean]
    def destroyed?
      @destroyed
    end

    # Retrieve model attributes from the backend storage
    #
    # @return [self]
    def reload
      raise NotImplementedError
    end

    # Remove the resource from the backend storage
    #
    # @return [Boolean]
    def destroy
      @destroyed = true
      freeze
    end

    # Assign attributes from the given hash and persist the model
    #
    # @param [Hash<[Symbol, String] => Any>] params
    # @return [Boolean]
    def update_attributes(params = {})
      assign_attributes(params)
      save
    end

    # Persist the model into the backend storage
    #
    # @raise [Kalimba::KalimbaError] if fails to obtain the subject for a new record
    # @return [Boolean]
    def save(options = {})
      @previously_changed = changes
      @changed_attributes.clear
      true
    end

    def logger
      self.class.logger
    end

    private

    def read_attribute(name, *args)
      value = attributes[name]
      if value.nil?
        self.class.properties[name][:collection] ? [] : nil
      else
        value
      end
    end
    alias_method :attribute, :read_attribute

    def write_attribute(name, value)
      attribute_will_change!(name) unless value == attributes[name]
      attributes[name] = value
    end

    # Overridden implementation should return URI for the subject, generated by
    # using specific random/default/sequential URI generation capabilities.
    # Otherwise it should return nil.
    #
    # @raise [Kalimba::KalimbaError] if cannot generate subject URI
    # @return [URI, nil]
    def generate_subject
      if self.class.base_uri
        s = self.class.base_uri.dup
        s.fragment = SecureRandom.urlsafe_base64
        s
      else
        raise Kalimba::KalimbaError, "Cannot generate subject without a base URI"
      end
    end

    def type_cast_to_rdf(value, datatype)
      if value.respond_to?(:to_rdf)
        value.to_rdf
      else
        if XmlSchema.datatype_of(value) == datatype
          value
        else
          v = XmlSchema.instantiate(value.to_s, datatype) rescue nil
          !v.nil? && XmlSchema.datatype_of(v) == datatype ? v : nil
        end
      end
    end

    def type_cast_from_rdf(value, datatype)
      if value.is_a?(URI)
        klass = rdfs_class_by_datatype(datatype)
        if klass
          klass.for(value.fragment)
        else
          anonymous_class_from(value, datatype).for(value.fragment)
        end
      else
        value
      end
    end

    def anonymous_class_from(uri, datatype)
      (uri = uri.dup).fragment = nil
      Class.new(Kalimba::Resource).tap do |klass|
        klass.class_eval do
          base_uri uri
          type datatype
        end
      end
    end

    def rdfs_class_by_datatype(datatype)
      Kalimba::Resource.descendants.detect {|a| a.type == datatype }
    end
  end
end
