require "kalimba/persistence/redlander"
require "kalimba"

support_dir = File.join(File.dirname(__FILE__), "support")
Dir.foreach(support_dir) do |ext|
  require File.join(support_dir, ext) if ext.end_with?(".rb")
end

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
    class Human < Kalimba::Resource
      type "http://schema.org/Human"
      base_uri "http://example.org/people"
      property :name, :predicate => "http://xmlns.com/foaf/0.1#name", :datatype => NS::XMLSchema["string"]
      has_many :duties, :predicate => "http://works.com#duty", :datatype => NS::XMLSchema["string"]
    end

    class Engineer < Kalimba::Resource
      type "http://schema.org/Engineer"
      base_uri "http://example.org/people"
      property :rank, :predicate => "http://works.com#rank", :datatype => NS::XMLSchema["integer"]
      property :retired, :predicate => "http://works.com#retired", :datatype => NS::XMLSchema["date"]
      property :boss, :predicate => "http://works.com#boss", :datatype => "http://schema.org/Engineer"
      has_many :duties, :predicate => "http://works.com#duty", :datatype => NS::XMLSchema["string"]
      has_many :coworkers, :predicate => "http://works.com#coworker", :datatype => "http://schema.org/Engineer"
    end
  end

  config.before do
    Kalimba.repository.statements.delete_all
  end
end
