require 'active_support/concern'

module Spree
  class Order
    module LoyaltyPoints
      extend ActiveSupport::Concern

      def loyalty_points_total
        loyalty_points_transactions.sum(:loyalty_points)
      end

      def award_loyalty_points
        loyalty_points_earned = loyalty_points_for(loyalty_points_eligible_total)
        if !loyalty_points_used?
          create_credit_transaction(loyalty_points_earned)
        end
      end

      def loyalty_points_awarded?
        loyalty_points_transactions.count > 0
      end

      def loyalty_points_used?
        payments.any_with_loyalty_points?
      end

      module ClassMethods
        def credit_loyalty_points_to_user since=nil
          orders = uncredited_orders
          orders = orders.where('`spree_orders`.`completed_at` > ?', since) if since

          orders.each do |order|
            order.award_loyalty_points
          end
        end

        def uncredited_orders
          points_period = Spree::Config.loyalty_points_award_period
          Spree::Order.with_uncredited_loyalty_points(points_period).
            where.not(spree_orders: { state: INELIGIBLE_ORDER_STATES })
        end
      end

      def create_credit_transaction(points)
        user.present? && user.loyalty_points_transactions.create(source: self, loyalty_points: points)
      end

      def create_debit_transaction(points)
        return unless points > 0
        user.present? && user.loyalty_points_transactions.create(source: self, loyalty_points: (-points))
      end

      private

      def complete_loyalty_points_payments
        payments.by_loyalty_points.with_state('checkout').each { |payment| payment.complete! }
      end

    end
  end
end
