
ENV["RAILS_ENV"] = 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'

RSpec.configure do |config|

  # If true, the base class of anonymous controllers will be inferred automatically.
  # This will be the default behavior in future versions of rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  config.raise_errors_for_deprecations!
  config.infer_spec_type_from_file_location!

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Use FactoryGirl short-cuts
  config.include FactoryGirl::Syntax::Methods

  # Mock current_user if needed
  config.include Devise::TestHelpers, type: :controller

  config.before(:suite) do
    DatabaseCleaner.orm = :mongoid
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end