require "redlander"
require "kalimba/persistence"

module Kalimba
  module Persistence
    # Mapping of database options from Rails' database.yml
    # to those that Redland::Model expects
    REPOSITORY_OPTIONS_MAPPING = {
      "adapter" => :storage,
      "database" => :name
    }

    class << self
      def backend
        Kalimba::Persistence::Redlander
      end

      def repository(options = {})
        ::Redlander::Model.new(remap_options(options))
      end

      private

      def remap_options(options = {})
        options = Hash[options.map {|k, v| [REPOSITORY_OPTIONS_MAPPING[k] || k, v] }].symbolize_keys
        options[:storage] =
          case options[:storage]
          when "sqlite3"
            "sqlite"
          else
            options[:storage]
          end

        options
      end
    end

    # Redlander-based persistence module
    module Redlander
      extend ActiveSupport::Concern
      include Kalimba::Persistence

      module ClassMethods
        def find_each(options = {})
          if block_given?
            attributes = (options[:conditions] || {}).stringify_keys

            q = "SELECT ?subject WHERE { #{resource_definition} . #{attributes_to_graph_query(attributes)} }"
            q << " LIMIT #{options[:limit]}" if options[:limit]

            logger.debug(q) if logger

            Kalimba.repository.query(q) do |binding|
              yield self.for(binding["subject"].uri.fragment)
            end
          else
            enum_for(:find_each, options)
          end
        end

        def find_by_id(id_value)
          record = self.for(id_value)
          record.new_record? ? nil : record
        end

        def exist?(attributes = {})
          attributes = attributes.stringify_keys
          q = "ASK { #{resource_definition} . #{attributes_to_graph_query(attributes)} }"
          logger.debug(q) if logger
          Kalimba.repository.query(q)
        end

        def create(attributes = {})
          record = new(attributes)
          record.save
          record
        end

        def destroy_all
          logger.debug("destroying all #{self.name.pluralize}") if logger
          Kalimba.repository.transaction do
            Kalimba.repository.statements.each(:predicate => NS::RDF["type"], :object => type) do |statement|
              Kalimba.repository.statements.delete_all(:subject => statement.subject)
            end
          end
        end

        def count(attributes = {})
          q = "SELECT (COUNT(?subject) AS _count) WHERE { #{resource_definition} . #{attributes_to_graph_query(attributes.stringify_keys)} }"
          logger.debug(q) if logger

          # using SPARQL 1.1, because SPARQL 1.0 does not support COUNT
          c = Kalimba.repository.query(q, :language => "sparql")[0]
          c ? c["_count"].value : 0
        end


        private

        def resource_definition
          if type
            [ "?subject", ::Redlander::Node.new(NS::RDF['type']), ::Redlander::Node.new(type) ].join(" ")
          else
            raise KalimbaError, "resource is missing type declaration"
          end
        end

        def attributes_to_graph_query(attributes = {})
          attributes.map { |name, value|
            if value.is_a?(Enumerable)
              value.map { |v| attributes_to_graph_query(name => v) }.join(" . ")
            else
              [ "?subject",
                ::Redlander::Node.new(properties[name][:predicate]),
                ::Redlander::Node.new(value)
              ].join(" ")
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
        logger.debug("reloading #{self.inspect}") if logger
        self.class.properties.each { |name, _| attributes[name] = retrieve_attribute(name) }
        self
      end

      def destroy
        if !destroyed? && persisted?
          Kalimba.repository.transaction do
            logger.debug("destroying #{self.inspect}") if logger
            Kalimba.repository.statements.delete_all(:subject => subject)
          end
          super
        else
          false
        end
      end

      def save(options = {})
        @subject ||= generate_subject
        logger.debug("saving #{self.inspect}") if logger
        Kalimba.repository.transaction do
          store_type && store_attributes(options) && super
        end
      end

      private

      def read_attribute(name, *args)
        if changed.include?(name) || !persisted?
          super
        else
          attributes[name] = retrieve_attribute(name)
        end
      end
      alias_method :attribute, :read_attribute

      def write_attribute(name, value)
        unless changed_attributes.include?(name)
          orig_value = read_attribute(name)
          unless value == orig_value
            orig_value = orig_value.duplicable? ? orig_value.clone : orig_value
            changed_attributes[name] = orig_value
          end
        end
        attributes[name] = value
      end

      def store_type
        st = ::Redlander::Statement.new(subject: subject, predicate: NS::RDF["type"], object: self.class.type)
        Kalimba.repository.statements.add(st)
      end

      def store_attributes(options = {})
        if new_record?
          attributes.all? { |name, value| value.blank? || store_attribute(name, options) }
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

      def store_single_value(value, predicate, datatype, options = {})
        value =
          if value.is_a?(Kalimba::Resource)
            store_single_resource(value, options)
          else
            if value.respond_to?(:to_rdf)
              value.to_rdf
            else
              type_cast_to_rdf(value, datatype)
            end
          end
        if value
          statement = ::Redlander::Statement.new(:subject => subject, :predicate => predicate, :object => ::Redlander::Node.new(value))
          Kalimba.repository.statements.add(statement)
        else
          # if value turned into nil or false upon conversion/typecasting to RDF,
          # do not count this as an error
          true
        end
      end

      def store_single_resource(resource, options)
        # avoid cyclic saves
        if options[:parent_subject] != resource.subject &&
            must_be_persisted?(resource)
          resource.save(:parent_subject => subject)
        end
      end

      def must_be_persisted?(resource)
        resource.changed? || resource.new_record?
      end

      def rdfs_class_by_datatype(datatype)
        Kalimba::Resource.descendants.detect {|a| a.type == datatype }
      end
    end
  end
end
