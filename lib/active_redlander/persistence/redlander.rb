require "redlander"

module ActiveRedlander
  module Persistence
    # Redlander-based persistence module
    module Redlander
      module ClassMethods
        def create_repository(options = {})
          ::Redlander::Model.new(options)
        end
      end

      def new_record?
        !persisted?
      end

      def persisted?
        @persisted ||= !subject.nil? && self.class.repository.statements.exist?(:subject => subject)
      end

      def retrieve_attribute(name)
        raise "TODO"
      end

      def store_attribute(name)
        delete_previous_data(name)
        add_new_data(name)
      end

      def reload
        raise "TODO"
      end

      def save
        update_types_data
        changes.each_key { |name| store_attribute(name) }
      end

      private

      def generate_subject
        nil
      end

      def update_types_data
        existing = self.class.types.map do |type|
          ::Redlander::Statement.new(:subject => subject, :predicate => NS::RDF["type"], :object => type)
        end
        deleting = []

        self.class.repository.statements.each(:subject => subject, :predicate => NS::RDF["type"]) do |statement|
          if existing.include?(statement)
            existing.delete(statement)
          else
            deleting << statement
          end
        end

        existing.each { |statement| self.class.repository.statements.add(statement) }
        deleting.each { |statement| self.class.repository.statements.delete(statement) }
      end

      def delete_previous_data(name)
        predicate = self.class.properties[name][:predicate]
        previous_value = ::Redlander::Node.new(attribute_was(name))
        if previous_value
          previous_statement = ::Redlander::Statement.new(:subject => subject, :predicate => predicate, :object => previous_value)
          self.class.repository.statements.delete(previous_statement)
        end
      end

      def add_new_data(name)
        predicate = self.class.properties[name][:predicate]
        value = read_attribute(name)
        if value
          value = ::Redlander::Node.new(value)
          statement = ::Redlander::Statement.new(:subject => subject, :predicate => predicate, :object => value)
          self.class.repository.statements.add(statement)
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end
  end
end
