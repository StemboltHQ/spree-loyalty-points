Spree::BaseController.class_eval do
  def rewards_name
    # Precursor to Spree 2.3
    "test"
  end
  helper_method :rewards_name
end
