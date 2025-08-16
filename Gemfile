source "https://rubygems.org"

gem "bcrypt", "~> 3.1.7"
gem "bootsnap", require: false
gem "jwt"
gem "kamal", require: false
gem "pagy"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

# Grape
gem "grape"
gem "grape-entity"
gem "grape-swagger"
gem "grape-swagger-entity"
gem "grape-swagger-rails"

# Performance and Error Tracking
gem "rollbar"
gem "scout_apm"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"

  # Code Quality & Linting
  gem "rubocop-rails-suite", require: false

  # Rspec
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails", "~> 8.0.2"

  # Security
  gem "brakeman", require: false
  gem "bundler-audit", require: false
end

group :development do
  # Performance
  gem "bullet"
end

group :test do
  gem "shoulda-matchers"
  gem "simplecov", require: false
end
