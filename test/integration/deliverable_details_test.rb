require 'test_helper'

class DeliverableDetailsShowTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main').reload
    @contract = Contract.generate!(:project => @project, :billable_rate => 10)
    @manager = User.generate!
    @deliverable1 = RetainerDeliverable.spawn(:contract => @contract, :manager => @manager, :title => "Retainer", :start_date => '2010-01-01', :end_date => '2010-03-31')
    @deliverable1.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10)
    @deliverable1.overhead_budgets << OverheadBudget.spawn(:budget => 200, :hours => 10)

    @deliverable1.save!
    @user = User.generate_user_with_permission_to_manage_budget(:project => @project)
    
    login_as(@user.login, 'contracts')
  end

  context "for an anonymous JS request" do
    should "require login" do
      logout

      visit "/projects/#{@project.id}/contracts/#{@contract.id}/deliverables/#{@deliverable1.id}", :get, {:format => 'js', :as => 'deliverable_details_row'}

      assert_response :unauthorized
    end

  end

  context "for an unauthorized JS request" do
    should "be forbidden" do
      logout

      @user = User.generate!(:password => 'test', :password_confirmation => 'test')
      login_as(@user.login, 'test')

      visit "/projects/#{@project.id}/contracts/#{@contract.id}/deliverables/#{@deliverable1.id}", :get, {:format => 'js', :as => 'deliverable_details_row'}

      assert_response :forbidden
    end

  end


  context "for an authorized JS request" do
    should "render the details for the deliverable" do
      visit "/projects/#{@project.id}/contracts/#{@contract.id}/deliverables/#{@deliverable1.id}", :get, {:format => 'js', :as => 'deliverable_details_row'}

      assert_response :success
      assert_select ".deliverable_details_outer_wrapper_#{@deliverable1.id}"
      assert_select "table#deliverables", :count => 0 # Not the full table
      assert_select "tr#deliverable_details_#{@deliverable1.id}", :count => 0 # Not the wrapper tr

    end

    should "filter the details based on the period" do
      assert_equal 300, @deliverable1.labor_budget_total
      assert_equal 600, @deliverable1.overhead_budget_total
      assert_equal 300, @deliverable1.total # Contract rate * 30 hours (labor)
      
      visit "/projects/#{@project.id}/contracts/#{@contract.id}/deliverables/#{@deliverable1.id}", :get, {:format => 'js', :as => 'deliverable_details_row', :period => '2010-02'}

      assert_response :success
      assert_select ".deliverable_details_outer_wrapper_#{@deliverable1.id}" do
        assert_select "td.labor_budget_total", '100'
        assert_select "td.overhead_budget_total", '200'
        assert_select "td.total", '100'

        assert_select "select.retainer_period_change" do
          assert_select "option[selected=selected]", "February 2010"
        end
      end
      
    end

  end
end
