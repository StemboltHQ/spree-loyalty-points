Spree::ReturnAuthorization.class_eval do

  def update_loyalty_points
    order.create_debit_transaction(order.loyalty_points_for(order.loyalty_points_eligible_total))
  end

end

Spree::ReturnAuthorization.state_machine.after_transition :to => :received, :do => :update_loyalty_points
