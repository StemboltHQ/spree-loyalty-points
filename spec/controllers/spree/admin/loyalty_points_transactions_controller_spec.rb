require 'spec_helper'

describe Spree::Admin::LoyaltyPointsTransactionsController do

  let(:user) { mock_model(Spree::User).as_null_object }
  let(:loyalty_points_transaction) { mock_model(Spree::LoyaltyPointsTransaction).as_null_object }
  let(:order) { mock_model(Spree::Order).as_null_object }

  before(:each) do
    controller.stub(:spree_current_user).and_return(user)
    user.stub(:generate_spree_api_key!).and_return(true)
    controller.stub(:authorize!).and_return(true)
    controller.stub(:authorize_admin).and_return(true)
    user.loyalty_points_transactions.stub(:create).and_return(loyalty_points_transaction)
    controller.stub(:parent_data).and_return({ :model_name => 'spree/order', :model_class => Spree::Order, :find_by => 'id' })
  end

  def default_host
    { :host => "http://test.host" }
  end


  context "when user found" do

    before(:each) do
      controller.stub(:parent).and_return(user)
      Spree::User.stub(:find_by).and_return(user)
    end

    describe "GET 'index'" do
      def send_request(params = {})
        get :index, params.merge!(:use_route => :spree)
      end

      it "assigns @loyalty_points_transactions" do
        send_request
        assigns[:loyalty_points_transactions].should_not be_nil
      end

      it "@user should receive loyalty_points_transactions" do
        user.should_receive(:loyalty_points_transactions)
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
        controller.stub(:load_resource_instance).and_return(loyalty_points_transaction)
      end

      it "assigns @loyalty_points_transaction" do
        send_request
        assigns[:loyalty_points_transaction].should_not be_nil
      end

      it "@loyalty_points_transaction should receive save" do
        loyalty_points_transaction.should_receive(:save)
        send_request
      end

    end

  end

  describe "GET 'order_transactions'" do
    def send_request(params = {})
      get :order_transactions, params.merge!(loyalty_points_transaction: attributes_for(:loyalty_points_transaction), :use_route => :spree, format: :json)
    end

    before :each do
      Spree::Order.stub(:find_by).and_return(order)
    end

    context "when user is found" do
      
      before(:each) do
        controller.stub(:parent).and_return(user)
        Spree::User.stub(:find_by).and_return(user)
        send_request
      end

      it "should redirect_to admin_users_path" do
        expect(response).to redirect_to(admin_users_path)
      end

      it "assigns @loyalty_points_transactions" do
        assigns[:loyalty_points_transactions].should_not be_nil
      end

      it "should be http success" do
        response.should be_success
      end

    end

    context "when user is not found" do
      
      before :each do
        Spree::User.stub(:find_by).and_return(nil)
        send_request
      end

      it "should redirect_to admin_users_path" do
        expect(response).to redirect_to(admin_users_path)
      end

    end

  end
end
