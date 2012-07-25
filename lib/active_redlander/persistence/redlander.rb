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
        predicate = self.class.properties[name][:predicate]

        self.class.repository.statements.delete_all(:subject => subject, :predicate => predicate)

        value = read_attribute(name)
        if value
          if self.class.properties[name][:collection]
            value.to_set.each { |v| store_single_value(predicate, v) }
          else
            store_single_value(predicate, value)
          end
        end
      end

      def reload
        raise "TODO"
      end

      def save
        update_types_data && changes.all? { |name, _| store_attribute(name) }
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

        existing.all? { |statement| self.class.repository.statements.add(statement) } &&
          deleting.all? { |statement| self.class.repository.statements.delete(statement) }
      end

      def store_single_value(predicate, value)
        statement = ::Redlander::Statement.new(:subject => subject, :predicate => predicate, :object => ::Redlander::Node.new(value))
        self.class.repository.statements.add(statement)
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end
  end
end
