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
    @deliverable.type = 'FixedDeliverable'
    create! { contract_url(@project, @contract) }
  end

  def update
    @deliverable = begin_of_association_chain.deliverables.find_by_id(params[:id])
    @deliverable.attributes = params[:fixed_deliverable] # TODO: hardcoded
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
