Spree::Order.class_eval do
  include Spree::LoyaltyPoints
  include Spree::Order::LoyaltyPoints

  has_many :loyalty_points_transactions, as: :source

  scope :loyalty_points_not_awarded, -> { includes(:loyalty_points_transactions).where(:spree_loyalty_points_transactions => { :source_id => nil } ) }

  scope :with_hours_since_payment, ->(num) { where('`spree_orders`.`paid_at` < ? ', num.hours.ago) }

  scope :with_uncredited_loyalty_points, ->(num) { with_hours_since_payment(num).loyalty_points_not_awarded }

  fsm = self.state_machines[:state]
  fsm.before_transition :from => fsm.states.map(&:name) - [:complete], :to => [:complete], :do => :complete_loyalty_points_payments

  def loyalty_points_eligible_total
    [line_items.select(&:loyalty_points_eligible).map(&:amount).sum + promo_total, 0].max
  end

end
