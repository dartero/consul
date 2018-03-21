require 'rails_helper'

feature 'Admin budget investment statuses' do

  let(:budget) { create(:budget) }

  background do
    admin = create(:administrator)
    login_as(admin.user)
  end

  context "Index" do
    scenario 'Displaying only not hidden statuses' do
      status1 = create(:budget_investment_status, budget: budget)
      status2 = create(:budget_investment_status, budget: budget)

      status1.destroy

      visit admin_budget_budget_investment_statuses_path(budget.id)

      expect(page).to_not have_content status1.name
      expect(page).to_not have_content status1.description

      expect(page).to have_content status2.name
      expect(page).to have_content status2.description
    end

    scenario 'Displaying no statuses text' do
      visit admin_budget_budget_investment_statuses_path(budget.id)

      expect(page).to have_content("There are no investment statuses created")
    end
  end

  context "New" do
    scenario "Create status" do
      visit admin_budget_budget_investment_statuses_path(budget.id)

      click_link 'Create new investment status'

      fill_in 'budget_investment_status_name', with: 'New status name'
      fill_in 'budget_investment_status_description', with: 'This status description'
      click_button 'Create Investment status'

      expect(page).to have_content 'New status name'
      expect(page).to have_content 'This status description'
    end

    scenario "Show validation errors on milestone form" do
      visit admin_budget_budget_investment_statuses_path(budget.id)

      click_link 'Create new investment status'

      fill_in 'budget_investment_status_description', with: 'This status description'
      click_button 'Create Investment status'

      within "#new_budget_investment_status" do
        expect(page).to have_content "can't be blank", count: 1
      end
    end
  end

  context "Edit" do
    scenario "Change name and description" do
      status = create(:budget_investment_status, budget: budget)

      visit admin_budget_budget_investment_statuses_path(budget.id)

      within("#budget_investment_status_#{status.id}") do
        click_link "Edit"
      end

      fill_in 'budget_investment_status_name', with: 'Other status name'
      fill_in 'budget_investment_status_description', with: 'Other status description'
      click_button 'Update Investment status'

      expect(page).to have_content 'Other status name'
      expect(page).to have_content 'Other status description'
    end
  end

  context "Delete" do
    scenario "Hides status" do
      status = create(:budget_investment_status, budget: budget)

      visit admin_budget_budget_investment_statuses_path(budget.id)

      within("#budget_investment_status_#{status.id}") do
        click_link "Delete"
      end

      expect(page).to_not have_content status.name
      expect(page).to_not have_content status.description
    end

    scenario "Removes all milestones with this status without description" do
      investment = create(:budget_investment, budget: budget)
      status = create(:budget_investment_status, budget: budget)
      milestone1 = create(:budget_investment_milestone,
                          status: status, investment: investment, description: nil)
      milestone2 = create(:budget_investment_milestone, status: status, investment: investment)

      visit admin_budget_budget_investment_statuses_path(budget.id)

      within("#budget_investment_status_#{status.id}") do
        click_link "Delete"
      end

      expect(Budget::Investment::Milestone.all.count).to be 1
    end
  end

end
