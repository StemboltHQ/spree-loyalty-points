require 'active_support/concern'

module Spree
  module TransactionsTotalValidation
    extend ActiveSupport::Concern

    def net_transactions_sum(trans_type, relation)
      transactions_total = relation.loyalty_points_transactions.sum(:loyalty_points)
      transactions_total + loyalty_points
    end

  end
end
