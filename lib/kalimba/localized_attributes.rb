require "active_support/concern"

module Kalimba
  # This module handles localized literals of RDF such that:
  #   1. they are presented as normal "single" attributes,
  #   2. storing the attribute in the same language overwrites
  #      only the attribute value in that language and does not
  #      delete this attribute values in other languages,
  module LocalizedAttributes
    extend ActiveSupport::Concern

    module ClassMethods
      def localizable_property?(name)
        !properties[name][:collection] && properties[name][:datatype] == NS::XMLSchema["string"]
      end
    end

    def retrieve_localizable_property(name)
      predicate = self.class.properties[name][:predicate]
      localized_names = send "localized_#{name.pluralize}"
      Kalimba.repository.statements.each(:subject => subject, :predicate => predicate) do |statement|
        value = statement.object.value
        lang = value.respond_to?(:lang) ? value.lang : nil
        localized_names[lang] = value
      end
      localized_names[I18n.locale] || localized_names[nil]
    end
  end
end
