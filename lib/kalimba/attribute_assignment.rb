module Kalimba
  module AttributeAssignment
    # Assign attributes from the given hash
    #
    # @param [Hash<[Symbol, String] => Any>] new_attributes
    # @param [Hash] options
    # @return [void]
    def assign_attributes(new_attributes = {}, options = {})
      return if new_attributes.blank?

      attributes = new_attributes.stringify_keys
      multi_parameter_attributes = []
      nested_parameter_attributes = []

      attributes.each do |k, v|
        if k.include?("(")
          multi_parameter_attributes << [ k, v ]
        elsif respond_to?("#{k}=")
          if v.is_a?(Hash)
            nested_parameter_attributes << [ k, v ]
          else
            send("#{k}=", v)
          end
        else
          raise UnknownAttributeError, "unknown attribute: #{k}"
        end
      end

      # assign any deferred nested attributes after the base attributes have been set
      nested_parameter_attributes.each do |k,v|
        send("#{k}=", v)
      end

      @mass_assignment_options = nil
      assign_multiparameter_attributes(multi_parameter_attributes)
    end

    private

    def assign_multiparameter_attributes(new_attributes)
    end
  end
end
