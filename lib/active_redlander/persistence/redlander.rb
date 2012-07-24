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

      def read_attribute(name)
        raise "TODO"
      end

      def write_attribute(name, value)
        raise "TODO"
      end

      def reload
        raise "TODO"
      end

      private

      def self.included(base)
        base.extend ClassMethods
      end
    end
  end
end
