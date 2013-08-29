ENV["RAILS_ENV"] = 'test'

require 'rubygems'
require 'database_cleaner'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.mock_with :rspec

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

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