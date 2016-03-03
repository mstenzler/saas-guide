require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :size => 10 }
end

Sidekiq.configure_server do |config|
  config.redis = { :size => 27 }
end
