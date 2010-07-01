class DeliverablesController < InheritedResources::Base
  unloadable

  respond_to :html

  before_filter :find_contract
  before_filter :authorize

  def index
    redirect_to contract_url(@project, @contract)
  end

  def create
    @deliverable = begin_of_association_chain.deliverables.build(params[:deliverable])
    if params[:deliverable] && params[:deliverable][:type] && ['FixedDeliverable','HourlyDeliverable'].include?(params[:deliverable][:type])
      @deliverable.type = params[:deliverable][:type]
    end
    create! { contract_url(@project, @contract) }
  end

  def update
    @deliverable = begin_of_association_chain.deliverables.find_by_id(params[:id])
    params[:deliverable] = params[:fixed_deliverable] || params[:hourly_deliverable]
    @deliverable.attributes = params[:deliverable]
    update! { contract_url(@project, @contract) }
  end

  def show
    redirect_to contract_url(@project, @contract)
  end

  def destroy
    destroy! { contract_url(@project, @contract) }
  end

  protected

  def begin_of_association_chain
    @contract
  end
  
  private
  
  def find_contract
    @contract = Contract.find(params[:contract_id])
    @project = @contract.project
  end

end
