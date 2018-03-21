class Budget
  class Investment
    class Milestone < ActiveRecord::Base
      include Imageable
      include Documentable
      documentable max_documents_allowed: 3,
                   max_file_size: 3.megabytes,
                   accepted_content_types: [ "application/pdf" ]

      belongs_to :investment
      belongs_to :status, class_name: 'Budget::Investment::Status'

      validates :title, presence: true
      validates :description, presence: true, unless: :has_status?
      validates :investment, presence: true
      validates :publication_date, presence: true

      scope :order_by_publication_date, -> { order(publication_date: :asc) }

      def self.title_max_length
        80
      end

      def has_status?
        status_id_changed? ? status_id_change[1] != nil : status_id.present?
      end
    end
  end
end
