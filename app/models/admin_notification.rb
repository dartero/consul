class AdminNotification < ActiveRecord::Base
  include Notifiable

  validates :title, presence: true
  validates :body, presence: true
  validates :segment_recipient, presence: true

  def list_of_recipients
    UserSegments.send(segment_recipient) if valid_segment_recipient?
  end

  def valid_segment_recipient?
    UserSegments.respond_to?(segment_recipient)
  end

  def draft?
    sent_at.nil?
  end

  def deliver
    list_of_recipients.pluck(:id).each do |recipient_user_id|
      Notification.add(recipient_user_id, self)
    end
    self.update(sent_at: Time.current)
  end
end
