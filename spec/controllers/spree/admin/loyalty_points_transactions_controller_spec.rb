require 'spec_helper'

describe Spree::Admin::LoyaltyPointsTransactionsController, :type => :controller do

  stub_authorization!
  
  let(:user) { mock_model(Spree::User).as_null_object }
  let(:loyalty_points_transaction) { mock_model(Spree::LoyaltyPointsTransaction).as_null_object }
  let(:order) { mock_model(Spree::Order).as_null_object }

  before(:each) do
    allow(user.loyalty_points_transactions).to receive(:create).and_return(loyalty_points_transaction)
    allow(controller).to receive(:parent_data).and_return({ :model_name => 'spree/order', :model_class => Spree::Order, :find_by => 'id' })
  end

  def default_host
    { :host => "http://test.host" }
  end


  context "when user found" do

    before(:each) do
      allow(controller).to receive(:parent).and_return(user)
      allow(Spree::User).to receive(:find_by).and_return(user)
    end

    describe "GET 'index'" do
      def send_request(params = {})
        get :index, params.merge!(:use_route => :spree)
      end

      it "assigns @loyalty_points_transactions" do
        send_request
        expect(assigns[:loyalty_points_transactions]).to_not be_nil
      end

      it "@user should receive loyalty_points_transactions" do
        expect(user).to receive(:loyalty_points_transactions)
        send_request
      end

      it "renders index template" do
        send_request
        expect(response).to render_template(:index)
      end

    end

    describe "POST 'create'" do
      def send_request(params = {})
        post :create, params.merge!(loyalty_points_transaction: attributes_for(:loyalty_points_transaction), :use_route => :spree)
      end

      before :each do
        allow(controller).to receive(:load_resource_instance).and_return(loyalty_points_transaction)
      end

      it "assigns @loyalty_points_transaction" do
        send_request
        expect(assigns[:loyalty_points_transaction]).to_not be_nil
      end

      it "@loyalty_points_transaction should receive save" do
        expect(loyalty_points_transaction).to receive(:save)
        send_request
      end

    end

  end

  describe "GET 'order_transactions'" do
    def send_request(params = {})
      get :order_transactions, params.merge!(loyalty_points_transaction: attributes_for(:loyalty_points_transaction), :use_route => :spree, format: :json)
    end

    before :each do
      allow(Spree::Order).to receive(:find_by).and_return(order)
    end

    context "when user is found" do
      
      before(:each) do
        allow(controller).to receive(:parent).and_return(user)
        allow(Spree::User).to receive(:find_by).and_return(user)
        send_request
      end

      it "should redirect_to admin_users_path" do
        expect(response).to redirect_to(admin_users_path)
      end

      it "assigns @loyalty_points_transactions" do
        expect(assigns[:loyalty_points_transactions]).to_not be_nil
      end

      it "should be http success" do
        expect(response).to be_success
      end

    end

    context "when user is not found" do
      
      before :each do
        allow(Spree::User).to receive(:find_by).and_return(nil)
        send_request
      end

      it "should redirect_to admin_users_path" do
        expect(response).to redirect_to(admin_users_path)
      end

    end

  end
end
