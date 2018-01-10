require 'rails_helper'

feature 'Budgets' do

  let(:budget) { create(:budget) }
  let(:level_two_user) { create(:user, :level_two) }

  scenario 'Index' do
    finished_budget1 = create(:budget, :finished)
    finished_budget2 = create(:budget, :finished)
    accepting_budget = create(:budget, :accepting)

    last_budget = accepting_budget
    group1 = create(:budget_group, budget: last_budget)
    group2 = create(:budget_group, budget: last_budget)

    heading1 = create(:budget_heading, group: group1)
    heading2 = create(:budget_heading, group: group2)

    visit budgets_path

    within("#budget_heading") do
      expect(page).to have_content(last_budget.name)
      expect(page).to have_content(last_budget.description)
      expect(page).to have_content("Actual phase")
      expect(page).to have_content("Accepting projects")
      expect(page).to have_link 'Help with participatory budgets'
      expect(page).to have_link 'See all phases'
    end

    last_budget.update_attributes(phase: 'publishing_prices')
    visit budgets_path

    expect(page).to have_content "Help with participatory budgets"

    within("#budget_heading") do
      expect(page).to have_content("Actual phase")
    end

    expect(page).to have_content accepting_budget.name

    within('#budget_info') do
      expect(page).to have_content group1.name
      expect(page).to have_content group2.name
      expect(page).to have_content heading1.name
      expect(page).to have_content last_budget.formatted_heading_price(heading1)
      expect(page).to have_content heading2.name
      expect(page).to have_content last_budget.formatted_heading_price(heading2)

      expect(page).to have_content finished_budget1.name
      expect(page).to have_content finished_budget2.name
    end
  end

  scenario 'Index shows only published phases' do

    budget.update(phase: :finished)

    budget.phases.drafting.update(starts_at: '30-12-2017', ends_at: '31-12-2017', enabled: true,
                                  description: 'Description of drafting phase',
                                  summary: '<p>This is the summary for drafting phase</p>')

    budget.phases.accepting.update(starts_at: '01-01-2018', ends_at: '10-01-2018', enabled: true,
                                   description: 'Description of accepting phase',
                                   summary: 'This is the summary for accepting phase')

    budget.phases.reviewing.update(starts_at: '11-01-2018', ends_at: '20-01-2018', enabled: false,
                                   description: 'Description of reviewing phase',
                                   summary: 'This is the summary for reviewing phase')

    budget.phases.selecting.update(starts_at: '21-01-2018', ends_at: '01-02-2018', enabled: true,
                                   description: 'Description of selecting phase',
                                   summary: 'This is the summary for selecting phase')

    budget.phases.valuating.update(starts_at: '10-02-2018', ends_at: '20-02-2018', enabled: false,
                                   description: 'Description of valuating phase',
                                   summary: 'This is the summary for valuating phase')

    budget.phases.publishing_prices.update(starts_at: '21-02-2018', ends_at: '01-03-2018', enabled: false,
                                           description: 'Description of publishing prices phase',
                                           summary: 'This is the summary for publishing_prices phase')

    budget.phases.balloting.update(starts_at: '02-03-2018', ends_at: '10-03-2018', enabled: true,
                                   description: 'Description of balloting phase',
                                   summary: 'This is the summary for balloting phase')

    budget.phases.reviewing_ballots.update(starts_at: '11-03-2018', ends_at: '20-03-2018', enabled: false,
                                           description: 'Description of reviewing ballots phase',
                                           summary: 'This is the summary for reviewing_ballots phase')

    budget.phases.finished.update(starts_at: '21-03-2018', ends_at: '30-03-2018', enabled: true,
                                  description: 'Description of finished phase',
                                  summary: 'This is the summary for finished phase')

    visit budgets_path

    expect(page).not_to have_content "This is the summary for drafting phase"
    expect(page).not_to have_content "December 30, 2017 - December 31, 2017"
    expect(page).not_to have_content "This is the summary for reviewing phase"
    expect(page).not_to have_content "January 11, 2018 - January 20, 2018"
    expect(page).not_to have_content "This is the summary for valuating phase"
    expect(page).not_to have_content "February 10, 2018 - February 20, 2018"
    expect(page).not_to have_content "This is the summary for publishing_prices phase"
    expect(page).not_to have_content "February 21, 2018 - March 01, 2018"
    expect(page).not_to have_content "This is the summary for reviewing_ballots phase"
    expect(page).not_to have_content "March 11, 2018 - March 20, 2018'"

    expect(page).to have_content "This is the summary for accepting phase"
    expect(page).to have_content "January 01, 2018 - January 20, 2018"
    expect(page).to have_content "This is the summary for selecting phase"
    expect(page).to have_content "January 21, 2018 - March 01, 2018"
    expect(page).to have_content "This is the summary for balloting phase"
    expect(page).to have_content "March 02, 2018 - March 20, 2018"
    expect(page).to have_content "This is the summary for finished phase"
    expect(page).to have_content "March 21, 2018 - March 29, 2018"

    expect(page).to have_css(".phase.active", count: 1)
  end

  context "Index map" do

    let(:group) { create(:budget_group, budget: budget) }
    let(:heading) { create(:budget_heading, group: group) }

    before do
      Setting['feature.map'] = true
    end

    scenario "Display investment's map location markers" , :js do
      investment1 = create(:budget_investment, heading: heading)
      investment2 = create(:budget_investment, heading: heading)
      investment3 = create(:budget_investment, heading: heading)

      investment1.create_map_location(longitude: 40.1234, latitude: 3.1234)
      investment2.create_map_location(longitude: 40.1235, latitude: 3.1235)
      investment3.create_map_location(longitude: 40.1236, latitude: 3.1236)

      visit budgets_path

      within ".map_location" do
        expect(page).to have_css(".map-icon", count: 3)
      end
    end

    scenario "Skip invalid map markers" , :js do
      map_locations = []
      map_locations << { longitude: 40.123456789, latitude: 3.12345678 }
      map_locations << { longitude: 40.123456789, latitude: "*******" }
      map_locations << { longitude: "**********", latitude: 3.12345678 }

      budget_map_locations = map_locations.map do |map_location|
        {
          lat: map_location[:latitude],
          long: map_location[:longitude],
          investment_title: "#{rand(999)}",
          investment_id: "#{rand(999)}",
          budget_id: budget.id
        }
      end

      allow_any_instance_of(BudgetsHelper).
      to receive(:current_budget_map_locations).and_return(budget_map_locations)

      visit budgets_path

      within ".map_location" do
        expect(page).to have_css(".map-icon", count: 1)
      end
    end
  end

  context "Advanced search" do

    context "Search by phase type" do

      scenario "Accepting Budget", :js do
        budget = create(:budget, :accepting)
        budget2 = create(:budget, :reviewing)
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Accepting projects', from: 'advanced_search_budget_phase')
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end

      scenario "Reviewing Budget", :js do
        budget = create(:budget, :reviewing)
        budget2 = create(:budget, :accepting)
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Reviewing projects', from: 'advanced_search_budget_phase')
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end

      scenario "Selecting Budget", :js do
        budget = create(:budget, :selecting)
        budget2 = create(:budget, :reviewing)
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Selecting projects', from: 'advanced_search_budget_phase')
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end

      scenario "Valuating Budget", :js do
        budget = create(:budget, :valuating)
        budget2 = create(:budget, :reviewing)
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Valuating projects', from: 'advanced_search_budget_phase')
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end

      scenario "Balloting Budget", :js do
        budget = create(:budget, :balloting)
        budget2 = create(:budget, :reviewing)
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Balloting projects', from: 'advanced_search_budget_phase')
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end

      scenario "Reviewing Ballots", :js do
        budget = create(:budget, :reviewing_ballots)
        budget2 = create(:budget, :reviewing)
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Reviewing Ballots', from: 'advanced_search_budget_phase')
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end

      scenario "Finished Ballots", :js do
        budget  = create(:budget, :finished)
        budget2 = create(:budget, :reviewing)
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Finished budget', from: 'advanced_search_budget_phase')
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end
    end
  end

  context "Search by date" do

    context "Predefined date ranges" do

      scenario "Last day", :js do
        budget = create(:budget, :accepting, created_at: 1.day.ago)
        budget2 = create(:budget, :reviewing, created_at: 2.days.ago)
        visit budgets_path
        click_link "js-advanced-search-title"
        select "Last 24 hours", from: "js-advanced-search-date-min"
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end

      scenario "Search by multiple filters", :js do
        budget = create(:budget, :accepting, created_at: 1.day.ago)
        budget2 = create(:budget, :selecting, created_at: 2.days.ago)
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Accepting projects', from: 'advanced_search_budget_phase')
        select "Last 24 hours", from: "js-advanced-search-date-min"
        click_button "Filter"
        within "#budgets" do
          expect(page).to have_content(budget.translated_phase)
          expect(page).to_not have_content(budget2.translated_phase)
        end
      end

      scenario "Maintain advanced search criteria", :js do
        visit budgets_path
        click_link "js-advanced-search-title"
        select('Accepting projects', from: 'advanced_search_budget_phase')
        select "Last 24 hours", from: "js-advanced-search-date-min"
        click_button "Filter"
        within "#js-advanced-search" do
          expect(page).to have_select('advanced_search[budget_phase]', selected: 'Accepting projects')
          expect(page).to have_select('advanced_search[date_min]', selected: 'Last 24 hours')
        end
      end

      scenario "Maintain custom date search criteria", :js do
        visit budgets_path
        click_link "js-advanced-search-title"
        select "Customized", from: "js-advanced-search-date-min"
        fill_in "advanced_search_date_min", with: 7.days.ago
        fill_in "advanced_search_date_max", with: 1.day.ago
        click_button "Filter"
        within "#js-advanced-search" do
          expect(page).to have_select('advanced_search[date_min]', selected: 'Customized')
          expect(page).to have_selector("input[name='advanced_search[date_min]'][value*='#{7.days.ago.strftime('%Y-%m-%d')}']")
          expect(page).to have_selector("input[name='advanced_search[date_max]'][value*='#{1.day.ago.strftime('%Y-%m-%d')}']")
        end
      end

    end
  end

  context 'Show' do

    scenario "List all groups" do
      group1 = create(:budget_group, budget: budget)
      group2 = create(:budget_group, budget: budget)

      visit budget_path(budget)

      budget.groups.each {|group| expect(page).to have_link(group.name)}
    end

    scenario "Links to unfeasible and selected if balloting or later" do
      budget = create(:budget, :selecting)
      group = create(:budget_group, budget: budget)

      visit budget_path(budget)

      expect(page).not_to have_link "See unfeasible investments"
      expect(page).not_to have_link "See investments not selected for balloting phase"

      click_link group.name

      expect(page).not_to have_link "See unfeasible investments"
      expect(page).not_to have_link "See investments not selected for balloting phase"

      budget.update(phase: :balloting)

      visit budget_path(budget)

      expect(page).to have_link "See unfeasible investments"
      expect(page).to have_link "See investments not selected for balloting phase"

      click_link group.name

      expect(page).to have_link "See unfeasible investments"
      expect(page).to have_link "See investments not selected for balloting phase"

      budget.update(phase: :finished)

      visit budget_path(budget)

      expect(page).to have_link "See unfeasible investments"
      expect(page).to have_link "See investments not selected for balloting phase"

      click_link group.name

      expect(page).to have_link "See unfeasible investments"
      expect(page).to have_link "See investments not selected for balloting phase"
    end

    scenario "Take into account headings with the same name from a different budget" do
      group1 = create(:budget_group, budget: budget, name: "New York")
      heading1 = create(:budget_heading, group: group1, name: "Brooklyn")
      heading2 = create(:budget_heading, group: group1, name: "Queens")

      budget2 = create(:budget)
      group2 = create(:budget_group, budget: budget2, name: "New York")
      heading3 = create(:budget_heading, group: group2, name: "Brooklyn")
      heading4 = create(:budget_heading, group: group2, name: "Queens")

      visit budget_path(budget)
      click_link "New York"

      expect(page).to have_css("#budget_heading_#{heading1.id}")
      expect(page).to have_css("#budget_heading_#{heading2.id}")

      expect(page).to_not have_css("#budget_heading_#{heading3.id}")
      expect(page).to_not have_css("#budget_heading_#{heading4.id}")
    end

  end

  context "In Drafting phase" do

    let(:admin) { create(:administrator).user }

    background do
      logout
      budget.update(phase: 'drafting')
      create(:budget)
    end

    context "Listed" do
      before { skip "At madrid we're not listing budgets" }

      scenario "Not listed to guest users at the public budgets list" do
        visit budgets_path

        expect(page).not_to have_content(budget.name)
      end

      scenario "Not listed to logged users at the public budgets list" do
        login_as(level_two_user)
        visit budgets_path

        expect(page).not_to have_content(budget.name)
      end

      scenario "Is listed to admins at the public budgets list" do
        login_as(admin)
        visit budgets_path

        expect(page).to have_content(budget.name)
      end
    end

    context "Shown" do
      scenario "Not accesible to guest users" do
        expect { visit budget_path(budget) }.to raise_error(ActionController::RoutingError)
      end

      scenario "Not accesible to logged users" do
        login_as(level_two_user)

        expect { visit budget_path(budget) }.to raise_error(ActionController::RoutingError)
      end

      scenario "Is accesible to admin users" do
        login_as(admin)
        visit budget_path(budget)

        expect(page.status_code).to eq(200)
      end
    end

  end

  context 'Accepting' do

    background do
      budget.update(phase: 'accepting')
    end

    context "Permissions" do

      scenario "Verified user" do
        login_as(level_two_user)

        visit budget_path(budget)
        expect(page).to have_link "Create a budget investment"

      end

      scenario "Unverified user" do
        user = create(:user)
        login_as(user)

        visit budget_path(budget)

        expect(page).to have_content "To create a new budget investment verify your account."
      end

      scenario "user not logged in" do
        visit budget_path(budget)

        expect(page).to have_content "To create a new budget investment you must sign in or sign up."
      end

    end
  end
end
