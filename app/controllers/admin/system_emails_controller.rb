class Admin::SystemEmailsController < Admin::BaseController

  before_action :load_system_email, only: [:view]

  def index
    @system_emails = %w(proposal_notification_digest)
  end

  def view
    case @system_email
    when "proposal_notification_digest"
      @notifications = dummy_proposal_notifications
      @subject = t('mailers.proposal_notification_digest.title', org_name: Setting['org_name'])
    end
  end

  private

  def load_system_email
    @system_email = params[:system_email_id]
  end

  def dummy_proposal_notifications
    generate_dummy_proposal_notifications unless proposal_notifications.count > 1
    proposal_notifications.limit(2)
  end

  def proposal_notifications
    Notification.where(notifiable_type: "ProposalNotification")
  end

  def generate_dummy_proposal_notifications
    Notification.create(user: current_user, notifiable: dummy_pedestrian_proposal_notification,
                        emailed_at: Time.current, read_at: Time.current)
    Notification.create(user: current_user, notifiable: dummy_dogs_park_proposal_notification,
                        emailed_at: Time.current, read_at: Time.current)
  end

  def dummy_pedestrian_proposal_notification
    ProposalNotification.create(proposal: Proposal.last || dummy_pedestrian_proposal,
                                title: t("seeds.proposals.pedestrian_streets.title"),
                                body: t("seeds.proposal_notifications.updated_notice.body"),
                                author: current_user)
  end

  def dummy_pedestrian_proposal
    Proposal.create(title: t("seeds.proposals.pedestrian_streets.title"),
                    summary: t("seeds.proposals.pedestrian_streets.summary"), skip_map: '1',
                    terms_of_service: '1', responsible_name: current_user.username,
                    author: current_user, hidden_at: Time.current)
  end

  def dummy_dogs_park_proposal_notification
    ProposalNotification.create(proposal: Proposal.last || dummy_dogs_park_proposal,
                                title: t("seeds.proposals.dogs_park.title"),
                                body: t("seeds.proposal_notifications.congratulations.body"),
                                author: current_user)
  end

  def dummy_dogs_park_proposal
    Proposal.create(title: t("seeds.proposals.dogs_park.title"),
                    summary: t("seeds.proposals.dogs_park.summary"), skip_map: '1',
                    terms_of_service: '1', responsible_name: current_user.username,
                    author: current_user, hidden_at: Time.current)
  end
end
