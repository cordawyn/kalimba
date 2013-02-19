require "active_support/concern"

module Kalimba
  # Raised by <tt>save!</tt> and <tt>create!</tt> when the record is invalid. Use the
  # +record+ method to retrieve the record which did not validate.
  #
  # @example
  #   begin
  #     complex_operation_that_calls_save!_internally
  #   rescue Kalimba::RecordInvalid => invalid
  #     puts invalid.record.errors
  #   end
  class RecordInvalid < KalimbaError
    attr_reader :record
    def initialize(record)
      @record = record
      errors = @record.errors.full_messages.join(", ")
      # TODO: use I18n later
      # super I18n.t("activerecord.errors.messages.record_invalid", :errors => errors)
      super "invalid record"
    end
  end

  module Validations
    extend ActiveSupport::Concern
    include ActiveModel::Validations

    module ClassMethods
      # Creates an object just like Persistence.create but calls <tt>save!</tt> instead of +save+
      # so an exception is raised if the record is invalid.
      def create!(attributes = {}, &block)
        if attributes.is_a?(Array)
          attributes.each { |attr| create!(attr, &block) }
        else
          create(attributes, &block) || (raise RecordInvalid, self)
        end
      end
    end

    def save(options = {})
      perform_validations(options) ? super : false
    end

    def save!(options = {})
      save || (raise RecordInvalid, self)
    end

    # Runs all the validations within the specified context. Returns true if no errors are found,
    # false otherwise.
    #
    # If the argument is false (default is +nil+), the context is set to <tt>:create</tt> if
    # <tt>new_record?</tt> is true, and to <tt>:update</tt> if it is not.
    #
    # Validations with no <tt>:on</tt> option will run no matter the context. Validations with
    # some <tt>:on</tt> option will only run in the specified context.
    def valid?(context = nil)
      context ||= (new_record? ? :create : :update)
      output = super(context)
      errors.empty? && output
    end

    protected

    def perform_validations(options={})
      perform_validation = options[:validate] != false
      perform_validation ? valid?(options[:context]) : true
    end
  end
end
