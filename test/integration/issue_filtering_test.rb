require 'test_helper'

class IssueFilteringTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project)
    @manager = User.generate!
    @deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager)
    @user = User.generate_user_with_permission_to_manage_budget(:project => @project).reload
    @user.admin = true # Getting odd permissions issues
    @user.save
    @issue1 = Issue.generate_for_project!(@project)
    @issue2 = Issue.generate_for_project!(@project, :deliverable => @deliverable)
    assert_equal @deliverable, @issue2.deliverable

    login_as(@user.login, 'contracts')
  end

  should "allow grouping issues by deliverable" do
    visit_project(@project)
    click_link "Issues"

    assert_select '#group_by' do
      assert_select 'option', "Deliverable"
    end

    select "Deliverable", :from => 'group_by'

    # Apply link is behind a JavaScript form
    visit "/projects/#{@project.identifier}/issues/?set_filter&group_by=deliverable_title"
    assert_response :success

    assert_select "tr.group" do
      assert_select "td", :text => /None/
    end

    assert_select "tr.group" do
      assert_select "td", :text => Regexp.new(@deliverable.title)
    end

  end
  
  should "allow grouping issues by contract" do
    visit_project(@project)
    click_link "Issues"

    assert_select '#group_by' do
      assert_select 'option', "Contract"
    end

    select "Contract", :from => 'group_by'

    # Apply link is behind a JavaScript form
    visit "/projects/#{@project.identifier}/issues/?set_filter&group_by=contract_name"
    assert_response :success

    assert_select "tr.group" do
      assert_select "td", :text => /None/
    end

    assert_select "tr.group" do
      assert_select "td", :text => Regexp.new(@contract.name)
    end

  end
  
end
