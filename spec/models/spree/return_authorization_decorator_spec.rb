require "spec_helper"

describe Spree::ReturnAuthorization do

  before(:each) do
    @return_authorization = create(:return_authorization_with_loyalty_points)
    allow(@return_authorization.order).to receive(:loyalty_points_for).and_return(40)
  end

  describe "update_loyalty_points callback" do

    it "should be included in state_machine after callbacks" do
      expect(Spree::ReturnAuthorization.state_machine.callbacks[:after].map { |callback| callback.instance_variable_get(:@methods) }.include?([:update_loyalty_points])).to be_truthy
    end

    it "should include only received in 'to' states" do
      expect(Spree::ReturnAuthorization.state_machine.callbacks[:after].select { |callback| callback.instance_variable_get(:@methods) == [:update_loyalty_points] }.first.branch.state_requirements.first[:to].values).to eq([:received])
    end

  end

  describe 'update_loyalty_points' do

    before :each do
      @debit_points = @return_authorization.order.loyalty_points_for(@return_authorization.order.loyalty_points_eligible_total)
      allow(@return_authorization.order.user).to receive(:loyalty_points_balance).and_return(@debit_points + 10)
      allow(@return_authorization).to receive(:loyalty_points).and_return(@debit_points + 20)
    end

    it "should receive create_debit_transaction with order's loyalty_points_for" do
      expect(@return_authorization.order).to receive(:create_debit_transaction).with(@debit_points)
      @return_authorization.update_loyalty_points
    end

  end

end
