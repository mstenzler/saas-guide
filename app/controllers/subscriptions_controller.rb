class SubscriptionsController < ApplicationController

	before_action :authenticate_user!

	def new
		@plans = Plan.all
	end

	def edit
		@account = Account.find(params[:id])
		@plans = Plan.all
	end

	def index
		@account = Account.find_by_email(current_user.email)
	end

	def create
		#Get the credit card details submitted by the form
		token = params[:stripeToken]
		plan  = params[:plan][:stripe_id]
		email = current_user.email
		current_account = Account.find_by_email(current_user.email)
		customer_id = current_account.customer_id
		current_plan = current_account.stripe_plan_id

		if customer_id.nil?
			#New customer -> Create a customer
			@customer = Stripe::Customer.create(
				:source => token,
				:plan => plan,
				:email => email
				)

			subscriptions = @customer.subscriptions
			@subscribed_plan = subscriptions.data.find { |o| o.plan.id == plan }

		else
			#customer exists
			#Get customer from stripe
			@customer = Stripe::Customer.retrieve(customer_id)
			@subscribed_plan = create_or_update_subscription(@customer, current_plan, plan)
		end

	 	#Get current perios end - This is a unix timestamp
	 	current_period_end = @subscribed_plan.current_period_end
	 	#Convert to datetime
	 	active_until = Time.at(current_period_end).to_datetime
	 	#update account model
	 	save_account_details(current_account, plan, @customer.id, active_until)

	 	redirect_to :root, :notice => "Successfully subscribed to #{@subscribed_plan.plan.name}"

	rescue => e
		redirect_to :back, :flash => { :error => e.message }

	end

	def cancel_subscription
		email = current_user.email
		current_account = Account.find_by_email(current_user.email)
		customer_id = current_account.customer_id
		current_plan = current_account.stripe_plan_id

		if current_plan.blank?
			raise "No plan found to unsubscribe/cancel"
		end

		#Fetch customer from Stripe
		customer = Stripe::Customer.retrieve(customer_id)

		#Get customer's subscriptions
		subscriptions = customer.subscriptions

		#Find the subscription that we want to cancel
		current_subscribed_plan = subscriptions.data.find { |o| o.plan.id == current_plan }

		if current_subscribed_plan.blank?
			raise "Subscription not found!!"
		end
		#Delete it
		current_subscribed_plan.delete

		#Update account model
		save_account_details(current_account, "", customer_id, Time.at(0).to_datetime)

		@message = "Subscription cancelled successfully"

	rescue => e
		redirect_to "/subscriptions", :flash => { :error => e.message }
	end

	def save_account_details(account, plan, customer_id, active_until)
		#Update account with the details
	 	account.stripe_plan_id = plan
	 	account.customer_id = customer_id
	 	account.active_until = active_until
	 	account.save!

	end

	def create_or_update_subscription(customer, current_plan, new_plan)
		subscriptions = customer.subscriptions
		#Get current subscription
		current_subscription = subscriptions.data.find { |o| o.plan.id == current_plan }

		if current_subscription.blank?
			#No current subscription
			#Maybe the customer unsubscribed previously or maybe the card was declined
			#So, create a new subscription to existing customer
			subscription = customer.subscriptions.create( { :plan => new_plan })
		else
			#Existing subscription found
			#must be an upgrade or a downgrade
			#So update existing dubscription with new plan
			current_subscription.plan = new_plan
			subscription = current_subscription.save
		end

		return subscription

	end

end
