require 'rails_helper'

feature 'Booth' do

  scenario "Officer with no booth assignments today" do
    officer = create(:poll_officer)

    login_through_form_as(officer.user)

    expect(page).to have_content "You don't have officing shifts today"
  end

  scenario "Officer with booth assignments another day" do
    officer = create(:poll_officer)
    create(:poll_officer_assignment, officer: officer, date: 1.day.from_now)

    login_through_form_as(officer.user)

    expect(page).to have_content "You don't have officing shifts today"
  end

  scenario 'Officer with single booth assignment today' do
    officer = create(:poll_officer)
    poll = create(:poll)

    booth = create(:poll_booth)

    booth_assignment = create(:poll_booth_assignment, poll: poll, booth: booth)
    create(:poll_officer_assignment, officer: officer, booth_assignment: booth_assignment, date: Date.today)

    login_through_form_as(officer.user)

    within("#officing-booth") do
      expect(page).to have_content "You are officing the booth located at #{booth.location}."
    end
  end

  scenario 'Officer with multiple booth assignments today' do
    officer = create(:poll_officer)
    poll = create(:poll)

    booth1 = create(:poll_booth)
    booth2 = create(:poll_booth)

    ba1 = create(:poll_booth_assignment, poll: poll, booth: booth1)
    ba2 = create(:poll_booth_assignment, poll: poll, booth: booth2)

    create(:poll_officer_assignment, officer: officer, booth_assignment: ba1, date: Date.today)
    create(:poll_officer_assignment, officer: officer, booth_assignment: ba2, date: Date.today)

    login_through_form_as(officer.user)

    expect(page).to have_content 'You have been signed in successfully.'
    expect(page).to have_content 'Choose your booth'

    select booth2.location, from: 'booth_id'
    click_button 'Enter'

    within("#officing-booth") do
      expect(page).to have_content "You are officing the booth located at #{booth2.location}."
    end
  end

  scenario "Display single booth for any number of polls" do
    officer = create(:poll_officer)

    booth1 = create(:poll_booth)
    booth2 = create(:poll_booth)

    poll1 = create(:poll)
    poll2 = create(:poll)

    ba1 = create(:poll_booth_assignment, poll: poll1, booth: booth1)
    ba2 = create(:poll_booth_assignment, poll: poll2, booth: booth2)
    ba3 = create(:poll_booth_assignment, poll: poll2, booth: booth2)

    create(:poll_officer_assignment, officer: officer, booth_assignment: ba1, date: Date.today)
    create(:poll_officer_assignment, officer: officer, booth_assignment: ba2, date: Date.today)
    create(:poll_officer_assignment, officer: officer, booth_assignment: ba3, date: Date.today)

    login_through_form_as(officer.user)

    expect(page).to have_content 'You have been signed in successfully.'
    expect(page).to have_content 'Choose your booth'

    expect(page).to have_select("booth_id", options: [booth1.location, booth2.location])
  end

end