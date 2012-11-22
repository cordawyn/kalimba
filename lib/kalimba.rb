require "set"
require "active_model" # TODO: not all is required?

# using Redlander backend (will be moved to a separate gem)
require "kalimba/persistence/redlander"

require "kalimba/version"
require "kalimba/exceptions"
require "kalimba/rdfs_class"
require "kalimba/resource"

module Kalimba
  class << self
    def repository
      @repository ||= Persistence.create_repository(@repository_options || {})
    end

    # Set ID of the repository used by this RDFS class
    #
    # @param [Hash] options options to be passed to the repository constructor
    # @return [void]
    def set_repository_options(options = {})
      @repository_options = options
    end
  end
end
