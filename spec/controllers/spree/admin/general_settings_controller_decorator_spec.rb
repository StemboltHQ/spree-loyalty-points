require 'spec_helper'

describe Spree::Admin::GeneralSettingsController do

  let(:user) { mock_model(Spree::User).as_null_object }

  before(:each) do
    controller.stub(:spree_current_user).and_return(user)
    user.stub(:generate_spree_api_key!).and_return(true)
    controller.stub(:authorize!).and_return(true)
    controller.stub(:authorize_admin).and_return(true)
  end
  
  describe "GET 'edit'" do

    it "assigns @preferences_loyalty_points" do
      get :edit, :use_route => :spree
      expect(assigns[:preferences_loyalty_points]).to eq({ :min_amount_required_to_get_loyalty_points => [""],
        :loyalty_points_awarding_unit => ["For example: Set this as 10 if we wish to award 10 points for $1 spent on the site."],
        :loyalty_points_redeeming_balance => [""],
        :loyalty_points_conversion_rate => ["For example: Set this value to 5 if we wish 1 loyalty point is equivalent to $5"],
        :loyalty_points_award_period => [""]
      })
    end

    it "renders edit template" do
      get :edit, :use_route => :spree
      expect(response).to render_template(:edit)
    end

  end

end
