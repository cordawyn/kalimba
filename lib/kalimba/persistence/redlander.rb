require "redlander"

module Kalimba
  module Persistence
    # Redlander-based persistence module
    module Redlander
      module ClassMethods
        def create_repository(options = {})
          ::Redlander::Model.new(options)
        end
      end

      def new_record?
        !(destroyed? || persisted?)
      end

      def persisted?
        !subject.nil? && Kalimba.repository.statements.exist?(:subject => subject)
      end

      def reload
        self.class.properties.each { |name, _| attributes[name] = retrieve_attribute(name) }
      end

      def destroy
        Kalimba.repository.statements.delete_all(:subject => subject)
      end

      def save
        update_types_data && changes.all? { |name, _| store_attribute(name) }
      end

      private

      def generate_subject
        nil
      end

      def retrieve_attribute(name)
        predicate = self.class.properties[name][:predicate]
        datatype = self.class.properties[name][:datatype]

        if self.class.properties[name][:collection]
          Kalimba.repository.statements
            .all(:subject => subject, :predicate => predicate)
            .map { |statement| type_cast_from_rdf(statement.object.value, datatype) }
        else
          statement = Kalimba.repository.statements.first(:subject => subject, :predicate => predicate)
          statement && type_cast_from_rdf(statement.object.value, datatype)
        end
      end

      def store_attribute(name)
        predicate = self.class.properties[name][:predicate]

        Kalimba.repository.statements.delete_all(:subject => subject, :predicate => predicate)

        value = read_attribute(name)
        if value
          datatype = self.class.properties[name][:datatype]
          if self.class.properties[name][:collection]
            value.to_set.all? do |v|
              v = type_cast_to_rdf(v, datatype)
              store_single_value(predicate, v) unless v.nil?
            end
          else
            value = type_cast_to_rdf(value, datatype)
            store_single_value(predicate, value) unless value.nil?
          end
        else
          true
        end
      end

      def type_cast_to_rdf(value, datatype)
        if value.respond_to?(:to_rdf)
          value.to_rdf
        elsif XmlSchema.datatype_of(value) == datatype
          value
        else
          v = XmlSchema.instantiate(value.to_s, datatype) rescue nil
          !v.nil? && XmlSchema.datatype_of(v) == datatype ? v : nil
        end
      end

      def type_cast_from_rdf(value, datatype)
        if self.class.type == datatype
          klass = self.class.rdfs_ancestors.detect {|a| a.type == self.class.type }
          klass.for(value)
        else
          value
        end
      end

      def update_types_data
        existing = self.class.types.map do |t|
          ::Redlander::Statement.new(:subject => subject, :predicate => NS::RDF["type"], :object => t)
        end
        deleting = []

        Kalimba.repository.statements.each(:subject => subject, :predicate => NS::RDF["type"]) do |statement|
          if existing.include?(statement)
            existing.delete(statement)
          else
            deleting << statement
          end
        end

        existing.all? { |statement| Kalimba.repository.statements.add(statement) } &&
          deleting.all? { |statement| Kalimba.repository.statements.delete(statement) }
      end

      def store_single_value(predicate, value)
        statement = ::Redlander::Statement.new(:subject => subject, :predicate => predicate, :object => ::Redlander::Node.new(value))
        Kalimba.repository.statements.add(statement)
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end
  end
end
