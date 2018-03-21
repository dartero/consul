require 'rails_helper'

describe Budget::Investment::Milestone do

  describe "Validations" do
    let(:milestone) { build(:budget_investment_milestone) }

    it "is valid" do
      expect(milestone).to be_valid
    end

    it "is not valid without a title" do
      milestone.title = nil
      expect(milestone).not_to be_valid
    end

    it "is not valid without a description if status is empty" do
      milestone.status = nil
      milestone.description = nil
      expect(milestone).not_to be_valid
    end

    it "is valid without a description if status is present" do
      milestone.description = nil
      expect(milestone).to be_valid
    end

    it "is not valid without an investment" do
      milestone.investment_id = nil
      expect(milestone).not_to be_valid
    end
  end

  describe "#has_status?" do
    let(:milestone) { build(:budget_investment_milestone) }

    it "returns true if an status_id is persisted" do
      expect(milestone.has_status?).to be true
    end

    it "returns true if an status_id is about to be saved to the record" do
      milestone.update(status_id: nil)

      status = create(:budget_investment_status)

      milestone.status_id = status.id
      expect(milestone.has_status?).to be true
    end

    it "returns false if the status_id is nil" do
      milestone.update(status_id: nil)

      expect(milestone.has_status?).to be false
    end

    it "returns false if the status_id is going to be persisted with nil value" do
      milestone.status_id = nil
      expect(milestone.has_status?).to be false
    end
  end

end
