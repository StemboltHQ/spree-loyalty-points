require 'spec_helper'

describe Spree::Admin::ReturnAuthorizationsController do

  let(:return_authorization) { mock_model(Spree::ReturnAuthorization).as_null_object }

  before :each do
    @user = return_authorization.order.user
    allow(controller).to receive(:load_resource_instance).and_return(return_authorization)
    allow(controller).to receive(:spree_current_user).and_return(@user)
    allow(controller).to receive(:authorize!).and_return(true)
    allow(controller).to receive(:authorize_admin).and_return(true)
  end

  describe "set_loyalty_points_transactions" do

    before :each do
      @loyalty_points_transactions = return_authorization.order.loyalty_points_transactions
      allow(return_authorization.order).to receive(:loyalty_points_transactions).and_return(@loyalty_points_transactions)
      allow(@loyalty_points_transactions).to receive(:page).and_return(@loyalty_points_transactions)
      allow(@loyalty_points_transactions).to receive(:per).and_return(@loyalty_points_transactions)
    end

    def send_request(params = {})
      get :new, params.merge!(:use_route => :spree)
    end

    it "assigns loyalty_points_transactions" do
      send_request
      expect(assigns[:loyalty_points_transactions]).to eq(@loyalty_points_transactions)
    end

    it "should receive loyalty_points_transactions on order" do
      expect(return_authorization.order).to receive(:loyalty_points_transactions)
      send_request
    end

    it "should receive page on loyalty_points_transactions" do
      expect(@loyalty_points_transactions).to receive(:page).with('2')
      send_request(page: 2)
    end

    context "when per_page is passed as a parameter" do

      it "should receive per with per_page on loyalty_points_transactions" do
        expect(@loyalty_points_transactions).to receive(:per).with('20')
        send_request(per_page: 20)
      end
    end

    context "when per_page is not passed as a parameter" do

      it "should receive per with Spree::Config[:orders_per_page] on loyalty_points_transactions" do
        expect(@loyalty_points_transactions).to receive(:per).with(Spree::Config[:orders_per_page])
        send_request
      end
    end
  end
end
