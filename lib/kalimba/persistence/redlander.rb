require "redlander"
require "kalimba/persistence"

module Kalimba
  module Persistence
    def self.backend
      Kalimba::Persistence::Redlander
    end

    def self.create_repository(options = {})
      ::Redlander::Model.new(options)
    end

    # Redlander-based persistence module
    module Redlander
      extend ActiveSupport::Concern
      include Kalimba::Persistence

      module ClassMethods
        def find_each(options = {})
          attributes = (options[:conditions] || {}).stringify_keys
          q = "SELECT ?subject WHERE { #{resource_definition} . #{attributes_to_graph_query(attributes)} }"
          if block_given?
            Kalimba.repository.query(q) do |binding|
              yield self.for(binding["subject"].uri)
            end
          else
            Kalimba.repository.query(q).map { |binding| self.for(binding["subject"].uri.fragment) }
          end
        end

        def exist?(attributes = {})
          attributes = attributes.stringify_keys
          q = "ASK { #{resource_definition} . #{attributes_to_graph_query(attributes)} }"
          Kalimba.repository.query(q)
        end

        def create(attributes = {})
          record = new(attributes)
          record.save
          record
        end

        def destroy_all
          Kalimba.repository.statements.each(:predicate => NS::RDF["type"], :object => type) do |statement|
            Kalimba.repository.statements.delete_all(:subject => statement.subject)
          end
        end

        private

        def resource_definition
          [ "?subject", ::Redlander::Node.new(NS::RDF['type']), ::Redlander::Node.new(type) ].join(" ")
        end

        def attributes_to_graph_query(attributes = {})
          attributes.map { |name, value|
            if value.is_a?(Enumerable)
              value.map { |v| attributes_to_graph_query(name => v) }.join(" . ")
            else
              [ "?subject",
                ::Redlander::Node.new(properties[name][:predicate]),
                ::Redlander::Node.new(value) ].join(" ")
            end
          }.join(" . ")
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
        self
      end

      def destroy
        if !destroyed? && persisted?
          Kalimba.repository.statements.delete_all(:subject => subject)
          super
        else
          false
        end
      end

      def save(options = {})
        @subject ||= generate_subject
        store_attributes(options) && update_types_data && super
      end

      private

      def store_attributes(options = {})
        if new_record?
          attributes.all? { |name, value| value.nil? || store_attribute(name, options) }
        else
          changes.all? { |name, _| store_attribute(name, options) }
        end
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

      def store_attribute(name, options = {})
        predicate = self.class.properties[name][:predicate]

        Kalimba.repository.statements.delete_all(:subject => subject, :predicate => predicate)

        value = read_attribute(name)
        if value
          datatype = self.class.properties[name][:datatype]
          if self.class.properties[name][:collection]
            value.to_set.all? { |v| store_single_value(v, predicate, datatype, options) }
          else
            store_single_value(value, predicate, datatype, options)
          end
        else
          true
        end
      end

      def type_cast_to_rdf(value, datatype)
        if XmlSchema.datatype_of(value) == datatype
          value
        else
          v = XmlSchema.instantiate(value.to_s, datatype) rescue nil
          !v.nil? && XmlSchema.datatype_of(v) == datatype ? v : nil
        end
      end

      def type_cast_from_rdf(value, datatype)
        klass = rdfs_class_by_datatype(datatype)
        klass ? klass.for(value) : value
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

      def store_single_value(value, predicate, datatype, options = {})
        value =
          if value.respond_to?(:to_rdf)
            if value.is_a?(Kalimba::Resource)
              # avoid cyclic saves
              if options[:parent_subject] != value.subject
                value.save(:parent_subject => subject) if value.changed? || value.new_record?
              else
                # do not count skipped cycled saves as errors
                true
              end
            end
            value.to_rdf
          else
            type_cast_to_rdf(value, datatype)
          end
        if value
          statement = ::Redlander::Statement.new(:subject => subject, :predicate => predicate, :object => ::Redlander::Node.new(value))
          Kalimba.repository.statements.add(statement)
        end
      end

      def rdfs_class_by_datatype(datatype)
        self.class.rdfs_ancestors.detect {|a| a.type == datatype }
      end
    end
  end
end
