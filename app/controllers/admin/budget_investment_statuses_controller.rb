class Admin::BudgetInvestmentStatusesController < Admin::BaseController

  before_action :load_budget
  before_action :load_status, only: [:edit, :update, :destroy]


  def index
    @statuses = Budget::Investment::Status.where(budget_id: @budget.id)
  end

  def new
    @status = Budget::Investment::Status.new
  end

  def create
    @status = Budget::Investment::Status.new(status_params)

    if @status.save
      redirect_to admin_budget_budget_investment_statuses_path(@budget),
                  notice: t('admin.statuses.create.notice')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @status.update(status_params)
      redirect_to admin_budget_budget_investment_statuses_path(@budget),
                  notice: t('admin.statuses.update.notice')
    else
      render :edit
    end
  end

  def destroy
    @status.destroy
    milestones_with_status_only
    redirect_to admin_budget_budget_investment_statuses_path(@budget),
                notice: t('admin.statuses.delete.notice')
  end

  private

  def load_budget
    @budget = Budget.find_by(slug: params[:budget_id]) || Budget.find_by(id: params[:budget_id])
  end

  def load_status
    @status = Budget::Investment::Status.find(params[:id])
  end

  def status_params
    params.require(:budget_investment_status).permit([:name, :description, :budget_id])
  end

  def milestones_with_status_only
    @status.milestones.each do |milestone|
      milestone.destroy unless milestone.description.present?
    end
  end
end
