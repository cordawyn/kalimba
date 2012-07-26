require "kalimba"

Kalimba.add_repository :default

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before :all do
    module Human
      extend Kalimba::Resource
      type "http://schema.org/Human"
      property :name, :predicate => "http://xmlns.com/foaf/0.1#name", :datatype => NS::XMLSchema["string"]
    end

    module Engineer
      extend Kalimba::Resource
      type "http://schema.org/Engineer"
      property :rank, :predicate => "http://works.com#rank", :datatype => NS::XMLSchema["int"]
      has_many :duties, :predicate => "http://works.com#duty", :datatype => NS::XMLSchema["string"]
      property :retired, :predicate => "http://works.com#retired", :datatype => NS::XMLSchema["date"]
    end
  end

  config.before do
    Kalimba.repositories[:default].statements.delete_all
  end
end
