class AddStatusToMilestones < ActiveRecord::Migration
  def change
    add_column :budget_investment_milestones, :status_id, :integer
    add_index :budget_investment_milestones, :status_id
  end
end
