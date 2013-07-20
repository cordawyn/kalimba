module Kalimba
  # CollectionProxy is an intermediary between collection association API
  # and its actual value.
  #
  # Its primary aim is tracking in-place changes of collections,
  # which is impossible via common means. For example:
  #
  #    wall.holes  # => []
  #    wall.holes << Hole.new
  #    wall.changed?  # => false
  #
  # It also delegates most of invoked methods to the actual value
  # in order to look like it.
  class CollectionProxy
    def initialize(owner, name)
      @name = name
      @owner = owner
    end

    def push(value)
      @owner.send(:attribute_will_change!, @name)
      owner_value << value
    end
    alias << push

    def is_a?(klass)
      owner_value.is_a?(klass)
    end

    def eql?(other)
      owner_value == other
    end
    alias == eql?

    def to_s
      owner_value.to_s
    end

    def inspect
      owner_value.inspect
    end


    private

    def method_missing(method_name, *args)
      if owner_value.respond_to?(method_name)
        owner_value.send(method_name, *args)
      else
        super
      end
    end

    def owner_value
      @owner.send(:read_attribute, @name)
    end
  end
end
