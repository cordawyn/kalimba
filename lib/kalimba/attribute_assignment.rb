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

      assign_multiparameter_attributes(multi_parameter_attributes)
    end

    private

    # Instantiates objects for all attribute classes that needs more than one constructor parameter. This is done
    # by calling new on the column type or aggregation type (through composed_of) object with these parameters.
    # So having the pairs written_on(1) = "2004", written_on(2) = "6", written_on(3) = "24", will instantiate
    # written_on (a date type) with Date.new("2004", "6", "24"). You can also specify a typecast character in the
    # parentheses to have the parameters typecasted before they're used in the constructor. Use i for Fixnum,
    # f for Float, s for String, and a for Array. If all the values for a given attribute are empty, the
    # attribute will be set to nil.
    def assign_multiparameter_attributes(pairs)
      execute_callstack_for_multiparameter_attributes(
        extract_callstack_for_multiparameter_attributes(pairs)
      )
    end

    def execute_callstack_for_multiparameter_attributes(callstack)
      errors = []
      callstack.each do |name, values_with_empty_parameters|
        begin
          send(name + "=", read_value_from_parameter(name, values_with_empty_parameters))
        rescue => ex
          errors << AttributeAssignmentError.new("error on assignment #{values_with_empty_parameters.values.inspect} to #{name}", ex, name)
        end
      end
      unless errors.empty?
        raise MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes"
      end
    end

    def read_value_from_parameter(name, values_hash_from_param)
      case self.class.properties[name][:datatype]
      when NS::XMLSchema["string"]
        read_other_parameter_value(LocalizedString, name, values_hash_from_param)
      when NS::XMLSchema["dateTime"], NS::XMLSchema["time"]
        read_time_parameter_value(name, values_hash_from_param)
      when NS::XMLSchema["date"]
        read_date_parameter_value(name, values_hash_from_param)
      else
        values_hash_from_param
      end
    end

    def read_other_parameter_value(klass, name, values_hash_from_param)
      max_position = extract_max_param_for_multiparameter_attributes(values_hash_from_param)
      values = (1..max_position).collect do |position|
        raise "Missing Parameter" if !values_hash_from_param.has_key?(position)
        values_hash_from_param[position]
      end
      klass.new(*values)
    end

    def extract_max_param_for_multiparameter_attributes(values_hash_from_param, upper_cap = 100)
      [values_hash_from_param.keys.max,upper_cap].min
    end

    def extract_callstack_for_multiparameter_attributes(pairs)
      pairs.inject({}) do |attributes, (multiparameter_name, value)|
        attribute_name = multiparameter_name.split("(").first
        attributes[attribute_name] = {} unless attributes.include?(attribute_name)

        parameter_value = value.empty? ? nil : type_cast_attribute_value(multiparameter_name, value)
        attributes[attribute_name][find_parameter_position(multiparameter_name)] ||= parameter_value
        attributes
      end
    end

    def type_cast_attribute_value(multiparameter_name, value)
      multiparameter_name =~ /\([0-9]*([if])\)/ ? value.send("to_" + $1) : value
    end

    def find_parameter_position(multiparameter_name)
      multiparameter_name.scan(/\(([0-9]*).*\)/).first.first.to_i
    end

    def read_time_parameter_value(name, values_hash_from_param)
      if values_hash_from_param.size == 2
        instantiate_time_using_two_fields(name, values_hash_from_param)
      else
        instantiate_time_using_many_fields(name, values_hash_from_param)
      end
    end

    def read_date_parameter_value(name, values_hash_from_param)
      return nil if (1..3).any? {|position| values_hash_from_param[position].blank?}
      set_values = [values_hash_from_param[1], values_hash_from_param[2], values_hash_from_param[3]]
      begin
        Date.new(*set_values)
      rescue ArgumentError # if Date.new raises an exception on an invalid date
        # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
        Time.new(*set_values).to_date
      end
    end

    def instantiate_time_using_two_fields(name, values_hash_from_param)
      value = [values_hash_from_param[1], values_hash_from_param[2]].join(" ")
      Time.parse(value) rescue nil
    end

    def instantiate_time_using_many_fields(name, values_hash_from_param)
      # If Date bits were not provided, error
      raise "Missing Parameter" if [1,2,3].any?{|position| !values_hash_from_param.has_key?(position)}
      max_position = extract_max_param_for_multiparameter_attributes(values_hash_from_param, 6)
      # If Date bits were provided but blank, then return nil
      return nil if (1..3).any? {|position| values_hash_from_param[position].blank?}

      set_values = (1..max_position).collect{|position| values_hash_from_param[position] }
      # If Time bits are not there, then default to 0
      (3..5).each {|i| set_values[i] = set_values[i].blank? ? 0 : set_values[i]}
      Time.new(*set_values)
    end
  end
end
