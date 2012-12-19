module Kalimba
  class Railtie < Rails::Railtie
    initializer "kalimba.initialize_database" do |app|
      Kalimba.set_repository_options app.config.database_configuration[Rails.env]
    end

    rake_tasks do
      load "kalimba/railties/repository.rake"
    end
  end
end
