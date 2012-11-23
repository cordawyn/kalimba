require "active_model/callbacks"

module Kalimba
  module Callbacks
    def destroy
      run_callbacks :destroy do
        super
      end
    end

    def save(options = {})
      run_callbacks :save do
        persistence_callback_type = new_record? ? :create : :update
        run_callbacks persistence_callback_type do
          super
        end
      end
    end

    private

    def self.included(klass)
      super
      klass.class_eval do
        extend ActiveModel::Callbacks
        define_model_callbacks :create, :update, :destroy, :save
      end
    end
  end
end
