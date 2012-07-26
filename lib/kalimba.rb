require "redlander"
require "active_model" # TODO: not all is required?

require "kalimba/version"
require "kalimba/exceptions"
require "kalimba/resource"

module Kalimba
  class << self
    def repositories
      @repositories ||= {}
    end

    def add_repository(name, options = {})
      repositories[name.to_sym] = Persistence.create_repository(options)
    end
  end
end
