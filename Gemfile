source 'https://rubygems.org'

ruby '1.9.3'
gem 'rails', '3.2.12'
gem 'thin', '>= 1.5.0'

gem 'mongoid', '>= 3.1.2'

gem 'heroku'

gem 'jquery-rails'
gem 'haml-rails', '>= 0.4'
gem 'devise', '>= 2.2.3'
gem 'figaro', '>= 0.6.3'
gem 'twitter-bootstrap-rails'

gem 'rabl' # JSON view template engine
gem 'oj' # JSON parser (for rabl)


group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier',       '>= 1.0.3'
end

group :development do
  gem 'quiet_assets', '>= 1.0.2'
  gem 'pry'
end

group :development, :test do
  gem 'rspec-rails', '~> 2.0'
  gem 'factory_girl_rails'
end

group :test do
  gem 'database_cleaner'
end