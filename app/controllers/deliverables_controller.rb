class DeliverablesController < InheritedResources::Base
  unloadable

  respond_to :html

  before_filter :find_contract
  before_filter :authorize

  helper :contracts
  helper :contract_formatter
  
  def index
    redirect_to contract_url(@project, @contract)
  end

  def create
    @deliverable = begin_of_association_chain.deliverables.build(params[:deliverable])
    if params[:deliverable] && params[:deliverable][:type] && Deliverable.valid_types.include?(params[:deliverable][:type])
      @deliverable.type = params[:deliverable][:type]
    end
    create!(:notice => l(:text_flash_deliverable_created, :name => @deliverable.title))  { contract_url(@project, @contract) }
  end

  def update
    @deliverable = begin_of_association_chain.deliverables.find_by_id(params[:id])
    params[:deliverable] = params[:fixed_deliverable] || params[:hourly_deliverable] || params[:retainer_deliverable]
    update!(:notice => l(:text_flash_deliverable_updated, :name => @deliverable.title)) { contract_url(@project, @contract) }
  end

  def show
    if show_partial?
      @period = extract_period(params[:period])
      render :partial => 'deliverables/details_row', :locals => {:contract => @contract, :deliverable => @contract.deliverables.find(params[:id]), :period => @period}
    else
      redirect_to contract_url(@project, @contract)
    end
  end

  def destroy
    destroy!(:notice => l(:text_flash_deliverable_deleted, :name => resource.title)) { contract_url(@project, @contract) }
  end

  protected

  def begin_of_association_chain
    @contract
  end

  # Is only a partial requested?
  def show_partial?
    params[:format] == 'js' && params[:as] == 'deliverable_details_row'
  end
  
  private
  
  def find_contract
    @contract = Contract.find(params[:contract_id])
    @project = @contract.project
  end

  def extract_period(param)
    period = nil
    if param.present? && param.match(/\A\d{4}-\d{2}\z/) # "YYYY-MM"
      year, month = param.split('-')
      period = Date.new(year.to_i, month.to_i, 1)
    end
    period
  end

end
