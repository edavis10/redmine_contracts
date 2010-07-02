module ContractsHelper
  def setup_nested_deliverable_records(deliverable)
    returning(deliverable) do |d|
      d.labor_expenses.build if d.labor_expenses.empty?
    end
  end
end
