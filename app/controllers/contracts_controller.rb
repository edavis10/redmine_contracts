class ContractsController < InheritedResources::Base
  unloadable

  respond_to :html

  before_filter :find_project
  before_filter :authorize

  private
  
  def find_project
    @project = Project.find(params[:project_id])
  end

end
