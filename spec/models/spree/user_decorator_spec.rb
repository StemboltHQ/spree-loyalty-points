require "spec_helper"

describe Spree::User do

  before(:each) do
    @user = FactoryGirl.build(:user_with_loyalty_points)
  end

  it "is valid with valid attributes" do
    expect(@user).to be_valid
  end

  it { is_expected.to have_many :loyalty_points_transactions }

  it "is invalid without numeric loyalty_points_balance" do
    is_expected.to validate_numericality_of(:loyalty_points_balance).only_integer
  end

  it "is invalid with a loyalty balance below 0" do
    @user.loyalty_points_balance = -1
    expect(@user.valid?).to be_falsey
  end

  describe 'loyalty_points_balance_sufficient?' do
    before :each do
      allow(Spree::Config).to receive(:loyalty_points_redeeming_balance).and_return(30)
    end

    context "when loyalty_points_balance greater than redeeming balance" do

      before :each do
        @user.loyalty_points_balance = 40
      end

      it "should return true" do
        expect(@user.loyalty_points_balance_sufficient?).to eq(true)
      end

    end

    context "when loyalty_points_balance equal to redeeming balance" do

      before :each do
        @user.loyalty_points_balance = 30
      end

      it "should return true" do
        expect(@user.loyalty_points_balance_sufficient?).to eq(true)
      end

    end

    context "when loyalty_points_balance less than redeeming balance" do

      before :each do
        @user.loyalty_points_balance = 20
      end

      it "should return false" do
        expect(@user.loyalty_points_balance_sufficient?).to eq(false)
      end

    end

  end

  describe 'has_sufficient_loyalty_points?' do
    before :each do
      @order = create(:order_with_loyalty_points)
      @order.total = BigDecimal.new(30.0, 2)
    end

    context "when loyalty_points_equivalent_currency greater than order total" do

      before :each do
        allow(@user).to receive(:loyalty_points_equivalent_currency).and_return(40)
      end

      it "should return true" do
        expect(@user.has_sufficient_loyalty_points?(@order)).to eq(true)
      end

    end

    context "when loyalty_points_equivalent_currency equal to order total" do

      before :each do
        allow(@user).to receive(:loyalty_points_equivalent_currency).and_return(30)
      end

      it "should return true" do
        expect(@user.has_sufficient_loyalty_points?(@order)).to eq(true)
      end

    end

    context "when loyalty_points_equivalent_currency less than order total" do

      before :each do
        allow(@user).to receive(:loyalty_points_equivalent_currency).and_return(20)
      end

      it "should return false" do
        expect(@user.has_sufficient_loyalty_points?(@order)).to eq(false)
      end

    end

  end

  describe 'loyalty_points_equivalent_currency' do

    let (:conversion_rate) { 5.0 }

    before :each do
      allow(Spree::Config).to receive(:loyalty_points_conversion_rate).and_return(conversion_rate)
    end

    it "should return balance * conversion_rate" do
      expect(@user.loyalty_points_equivalent_currency).to eq(@user.loyalty_points_balance * conversion_rate)
    end

  end

end
