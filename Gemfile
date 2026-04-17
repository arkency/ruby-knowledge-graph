source "https://rubygems.org"

gem "rails", "~> 8.1.2"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "mission_control-jobs"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

gem "rails_event_store"
gem "ruby_llm"
gem "neighbor"
gem "mcp"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails"
  gem "dotenv-rails"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "webmock"
  gem "database_cleaner-active_record"
end

group :development do
  gem "web-console"
end
