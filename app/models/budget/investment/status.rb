class Budget::Investment::Status < ActiveRecord::Base
  acts_as_paranoid column: :hidden_at

  belongs_to :budget
  has_many :milestones

  validates :budget, presence: true
  validates :name, presence: true
end
