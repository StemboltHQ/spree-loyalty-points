module Spree
  class LoyaltyPointsTransaction < ActiveRecord::Base

    belongs_to :user
    belongs_to :source, polymorphic: true

    validates :loyalty_points, :numericality => { :only_integer => true, :message => Spree.t('validation.must_be_int') }
    validates :balance, presence: true
    validate :source_or_comment_present

    scope :for_order, ->(order) { where(source: order) }

    before_create :generate_transaction_id

    after_create :update_user_balance
    before_create :update_balance

    private

      def update_user_balance
        user.increment(:loyalty_points_balance, loyalty_points)
        user.save!
      end

      def update_balance
        self.balance = user.loyalty_points_balance + loyalty_points
      end

      def source_or_comment_present
        unless source.present? || comment.present?
          errors.add :base, 'Source or Comment should be present'
        end
      end

      def generate_transaction_id
        begin
          self.transaction_id = (Time.current.strftime("%s") + rand(999999).to_s).to(15)
        end while Spree::LoyaltyPointsTransaction.where(:transaction_id => transaction_id).present? 
      end

  end
end
