require "redlander"
require "active_model" # TODO: not all is required?

require "active_redlander/version"
require "active_redlander/exceptions"
require "active_redlander/resource"

module ActiveRedlander
  class << self
    def repositories
      @repositories ||= {}
    end

    def add_repository(name, options = {})
      repositories[name.to_sym] = Persistence.create_repository(options)
    end
  end
end
