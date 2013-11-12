require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

require './lib/sidekiq/fancy'

run Sidekiq::Fancy
