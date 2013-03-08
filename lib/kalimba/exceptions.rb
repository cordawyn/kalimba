module Kalimba
  class KalimbaError < StandardError; end
  class UnknownAttributeError < KalimbaError; end
  class AttributeAssignmentError < KalimbaError
    attr_reader :exception, :attribute
    def initialize(message, exception, attribute)
      @exception = exception
      @attribute = attribute
      @message = message
    end
  end
  class MultiparameterAssignmentErrors < KalimbaError
    attr_reader :errors
    def initialize(errors)
      @errors = errors
    end
  end
end
