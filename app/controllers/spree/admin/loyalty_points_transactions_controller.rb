class Spree::Admin::LoyaltyPointsTransactionsController < Spree::Admin::ResourceController
  before_action :set_user, only: [:order_transactions]
  belongs_to 'spree/user'
  before_action :set_ordered_transactions, only: [:index]

  def order_transactions
    order = Spree::Order.find_by(id: params[:order_id])
    @loyalty_points_transactions = @user.loyalty_points_transactions.for_order(order).includes(:source).order(updated_at: :desc)
    respond_to do |format|
      format.json do
        render json: @loyalty_points_transactions.to_json(
          :include => {
            :source => {
              :only => [:id, :number]
            }
          },
          :only => [:source_type, :comment, :updated_at, :loyalty_points, :balance]
        )
      end
    end
  end

  protected

    def set_user
      unless @user = Spree::User.find_by(id: params[:user_id])
        redirect_to admin_users_path, notice: 'User not found'
      end
    end

    def set_ordered_transactions
      @loyalty_points_transactions = @loyalty_points_transactions.order(updated_at: :desc).
        page(params[:page]).
        per(params[:per_page] || Spree::Config[:orders_per_page])
    end

end
