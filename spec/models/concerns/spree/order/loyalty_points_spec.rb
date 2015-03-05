shared_examples_for "Order::LoyaltyPoints" do
  describe 'award_loyalty_points' do
    context "when payment not done via Loyalty Points" do
      before :each do
        allow(resource_instance).to receive(:loyalty_points_used?).and_return(false)
        allow(resource_instance).to receive(:loyalty_points_for).and_return(50)
      end

      it "should receive create_credit_transaction" do
        expect(resource_instance).to receive(:create_credit_transaction)
        resource_instance.award_loyalty_points
      end
    end

    context "when payment done via Loyalty Points" do
      before :each do
        allow(resource_instance).to receive(:loyalty_points_used?).and_return(true)
      end

      it "should not receive create_credit_transaction" do
        expect(resource_instance).to_not receive(:create_credit_transaction)
        resource_instance.award_loyalty_points
      end
    end
  end

  describe 'create_credit_transaction' do
    context "when quantity is not 0" do
      it "should add a Loyalty Points Credit Transaction" do
        expect {
          resource_instance.send(:create_credit_transaction, 30)
        }.to change{ Spree::LoyaltyPointsTransaction.count }.by(1)
      end

      it "should create a Loyalty Points Credit Transaction" do
        resource_instance.send(:create_credit_transaction, 30)
        expect(Spree::LoyaltyPointsTransaction.last.loyalty_points).to eq(30)
      end

      it "should create a Loyalty Points Credit Transaction" do
        resource_instance.send(:create_credit_transaction, 30)
        expect(Spree::LoyaltyPointsTransaction.last.user_id).to eq(resource_instance.user_id)
      end
      
      context 'when guest checkout' do
        before(:each) { allow(resource_instance).to receive(:user) }
        
        it 'should return false' do
          expect(resource_instance.send(:create_credit_transaction, 30)).to be_falsey
        end
      end
    end
  end

  describe 'create_debit_transaction' do
    context "when quantity is not 0" do
      it "should add a Loyalty Points Debit Transaction" do
        expect {
          resource_instance.send(:create_debit_transaction, 30)
        }.to change{ Spree::LoyaltyPointsTransaction.count }.by(1)
      end

      it "should create a Loyalty Points Debit Transaction" do
        resource_instance.send(:create_debit_transaction, 30)
        expect(Spree::LoyaltyPointsTransaction.last.loyalty_points).to eq(-30)
      end

      it "should create a Loyalty Points Credit Transaction" do
        resource_instance.send(:create_debit_transaction, 30)
        expect(Spree::LoyaltyPointsTransaction.last.user_id).to eq(resource_instance.user_id)
      end
      
      context 'when guest checkout' do
        before(:each) { allow(resource_instance).to receive(:user) }
        
        it 'should return false' do
          expect(resource_instance.send(:create_credit_transaction, 30)).to be_falsey
        end
      end

    end

    context "when quantity is 0" do
      
      it "should not add a Loyalty Points Debit Transaction" do
        expect {
          resource_instance.send(:create_debit_transaction, 0)
        }.to change{ Spree::LoyaltyPointsTransaction.count }.by(0)
      end

    end
  end

  describe 'loyalty_points_used?' do
    it "should receive any_with_loyalty_points? on payments" do
      expect(resource_instance.payments).to receive(:any_with_loyalty_points?)
      resource_instance.loyalty_points_used?
    end
  end

  describe 'complete_loyalty_points_payments' do
    before :each do
      allow(resource_instance.payments).to receive(:by_loyalty_points).and_return(resource_instance.payments)
      allow(resource_instance.payments).to receive(:with_state).with('checkout').and_return(resource_instance.payments)
    end

    it "should receive by_loyalty_points on payments" do
      expect(resource_instance.payments).to receive(:by_loyalty_points)
      resource_instance.send(:complete_loyalty_points_payments)
    end

    it "should receive with_state on payments" do
      expect(resource_instance.payments.by_loyalty_points).to receive(:with_state).with('checkout')
      resource_instance.send(:complete_loyalty_points_payments)
    end

    it "should receive complete on each payment" do
      resource_instance.payments.each do |payment|
        expect(payment).to receive(:complete!)
      end
      resource_instance.send(:complete_loyalty_points_payments)
    end
  end

  describe '.uncredited_orders' do
    before do
      allow(Spree::Config).to receive(:loyalty_points_award_period).and_return(0)
    end

    subject { Spree::Order.uncredited_orders }

    context "without transactions" do
      context "with a complete, cancelled, returned, and awaiting_return order" do
        let!(:returned_order) { create :order, state: "returned" }
        let!(:awaiting_return_order) { create :order, state: "awaiting_return" }
        let!(:complete_order) { create :order, state: "complete" }
        let!(:cancelled_order) { create :order, state: "canceled" }


        before do
          Spree::Order.all.each do |t|
            t.touch(:paid_at)
          end
        end

        it "only returns orders with states that aren't returned cancelled or awaiting return" do
          expect(subject.to_a).to eql([complete_order])
        end
      end
    end

    context "with transactions" do
      context "with two complete orders, one with a transaction" do
        let(:order1) { create :order, state: "complete" }
        let(:order2) { create :order, state: "complete" }

        before do
          order2.user.loyalty_points_transactions.create!(loyalty_points: 500, comment: "sups", source: order2)
          order2.touch(:paid_at)
          order1.touch(:paid_at)
          order2.reload
        end

        it "only returns the order without a transaction" do
          expect(subject.to_a).to eql([order1])
        end
      end
    end
  end

  describe ".credit_loyalty_points_to_user" do
    context "with a complete and paid order" do
      context 'when a date is supplied' do
        let(:uncredited_orders) { double }
        let(:since) { Time.local(2000,1,1) }

        before do
          allow(Spree::Order).to receive(:uncredited_orders) { uncredited_orders }
          expect(uncredited_orders).to receive(:where).with('`spree_orders`.`completed_at` > ?', since) { [] }
        end

        it "awards points to all orders past the date" do
          Spree::Order.credit_loyalty_points_to_user since
        end
      end

      context "when a date isn't supplied" do
        let!(:complete_order) { create :order, state: "complete" }

        before do
          allow(Spree::Config).to receive(:loyalty_points_award_period).and_return(0)
          complete_order.touch(:paid_at)
        end

        it "awards loyalty points to the order" do
          expect_any_instance_of(Spree::Order).to receive(:award_loyalty_points).once
          Spree::Order.credit_loyalty_points_to_user
        end
      end
    end
  end

  describe 'loyalty_points_awarded?' do
    context "when credit transactions are present" do
      it "should return true" do
        expect(resource_instance).to be_loyalty_points_awarded
      end
    end

    context "when credit transactions are absent" do
      before :each do
        resource_instance.loyalty_points_transactions = []
      end

      it "should return false" do
        expect(resource_instance).to_not be_loyalty_points_awarded
      end
    end
  end

  describe 'loyalty_points_total' do
    before :each do
      resource_instance.loyalty_points_transactions = create_list(:loyalty_points_transaction, 1, loyalty_points: 50)
      resource_instance.loyalty_points_transactions << create_list(:loyalty_points_transaction, 1, loyalty_points: -30)
    end

    it "should result in net loyalty points for that order" do
      expect(resource_instance.loyalty_points_total).to eq(20)
    end
  end
end
