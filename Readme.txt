#Seeding plan table

p1 = Stripe::Plan.retrieve("plan-free")
p1 = Stripe::Plan.retrieve("plan-good")
p1 = Stripe::Plan.retrieve("plan-awesome")

Plan.create(:stripe_id => p1.id, :name => p1.name, :price => p1.amount, :interval => p1.interval)


#Requiring sidekiq in console
require 'Sidekiq/api'


#Clear retry jobs
Sidekiq::RetrySet.new.clear

#Sidekiq Stats
stats = Sidekiq::Stats.new
