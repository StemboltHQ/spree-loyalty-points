class RemoveTypeFromLolaltyPointTransactions < ActiveRecord::Migration
  def change
    Spree::LoyaltyPointsTransaction.where(type: 'Debit').update_all('loyalty_points = loyalty_points * -1')
    remove_column :spree_loyalty_points_transactions, :type
  end
end
