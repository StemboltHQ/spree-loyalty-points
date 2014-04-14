require "spec_helper"

describe Spree::ReturnAuthorization do

  before(:each) do
    @return_authorization = create(:return_authorization_with_loyalty_points)
    @return_authorization.order.stub(:loyalty_points_for).and_return(40)
  end

  describe "update_loyalty_points callback" do

    it "should be included in state_machine after callbacks" do
      Spree::ReturnAuthorization.state_machine.callbacks[:after].map { |callback| callback.instance_variable_get(:@methods) }.include?([:update_loyalty_points]).should be_true
    end

    it "should include only received in 'to' states" do
      Spree::ReturnAuthorization.state_machine.callbacks[:after].select { |callback| callback.instance_variable_get(:@methods) == [:update_loyalty_points] }.first.branch.state_requirements.first[:to].values.should eq([:received])
    end

  end

  describe 'update_loyalty_points' do

    before :each do
      @debit_points = @return_authorization.order.loyalty_points_for(@return_authorization.order.loyalty_points_eligible_total)
      @return_authorization.order.user.stub(:loyalty_points_balance).and_return(@debit_points + 10)
      @return_authorization.stub(:loyalty_points).and_return(@debit_points + 20)
    end

    it "should receive create_debit_transaction with order's loyalty_points_for" do
      @return_authorization.order.should_receive(:create_debit_transaction).with(@debit_points)
      @return_authorization.update_loyalty_points
    end

  end

end
