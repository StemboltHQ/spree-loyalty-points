shared_examples_for "TransactionsTotalValidation" do

  describe "net_transactions_sum" do

    before :each do
      @total = relation.loyalty_points_transactions.sum(:loyalty_points) + resource_instance.loyalty_points
    end

    it "should return total" do
      resource_instance.send(:net_transactions_sum, @trans_type, relation).should eq(@total)
    end

  end

end
