desc "Create RDF storage"
namespace :db do
  task :setup do
    options = Rails.configuration.database_configuration[Rails.env] || {}
    Kalimba::Persistence.repository(options.merge(:new => true))
  end
end
