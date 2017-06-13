require 'csv'
class Proposal < ActiveRecord::Base
  include Flaggable
  include Taggable
  include Conflictable
  include Measurable
  include Sanitizable
  include Searchable
  include Filterable
  include HasPublicAuthor
  include Graphqlable

  acts_as_votable
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  RETIRE_OPTIONS = %w(duplicated started unfeasible done other)
  PROCEEDINGS = [ 'Derechos Humanos' ]

  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  belongs_to :geozone
  has_many :proposal_notifications
  has_many :comments, as: :commentable

  validates :title, presence: true
  validates :summary, presence: true
  validates :author, presence: true
  validates :responsible_name, presence: true

  validates :title, length: { in: 4..Proposal.title_max_length }
  validates :description, length: { maximum: Proposal.description_max_length }
  validates :responsible_name, length: { in: 6..Proposal.responsible_name_max_length }
  validates :retired_reason, inclusion: { in: RETIRE_OPTIONS, allow_nil: true }
  validates :proceeding, inclusion: { in: PROCEEDINGS, allow_nil: true }
  validates :sub_proceeding, presence: true, length: { in: 10..150 }, if: :proceeding?

  validates :terms_of_service, acceptance: { allow_nil: false }, on: :create

  before_validation :set_responsible_name

  before_save :calculate_hot_score, :calculate_confidence_score

  scope :for_render,               -> { includes(:tags) }
  scope :sort_by_hot_score ,       -> { reorder(hot_score: :desc) }
  scope :sort_by_confidence_score, -> { reorder(confidence_score: :desc) }
  scope :sort_by_created_at,       -> { reorder(created_at: :desc) }
  scope :sort_by_most_commented,   -> { reorder(comments_count: :desc) }
  scope :sort_by_random,           -> { reorder("RANDOM()") }
  scope :sort_by_relevance,        -> { all }
  scope :sort_by_flags,            -> { order(flags_count: :desc, updated_at: :desc) }
  scope :sort_by_archival_date,    -> { archived.sort_by_confidence_score }
  scope :archived,                 -> { where("proposals.created_at <= ?", Setting["months_to_archive_proposals"].to_i.months.ago) }
  scope :not_archived,             -> { where("proposals.created_at > ?", Setting["months_to_archive_proposals"].to_i.months.ago) }
  scope :last_week,                -> { where("proposals.created_at >= ?", 7.days.ago)}
  scope :retired,                  -> { where.not(retired_at: nil) }
  scope :not_retired,              -> { where(retired_at: nil) }
  scope :proceedings,              -> { where.not(proceeding: nil) }
  scope :not_proceedings,          -> { where(proceeding: nil) }
  scope :successful,               -> { where("cached_votes_up >= ?", Proposal.votes_needed_for_success) }
  scope :public_for_api,           -> { all }

  def to_param
    "#{id}-#{title}".parameterize
  end

  def searchable_values
    { title              => 'A',
      question           => 'B',
      author.username    => 'B',
      tag_list.join(' ') => 'B',
      geozone.try(:name) => 'B',
      summary            => 'C',
      description        => 'D',
      proceeding         => 'A',
      sub_proceeding     => 'A'
    }
  end

  def self.search(terms)
    by_code = self.search_by_code(terms.strip)
    by_code.present? ? by_code : self.pg_search(terms)
  end

  def self.search_by_code(terms)
    matched_code = self.match_code(terms)
    results = where(id: matched_code[1]) if matched_code
    return results if (results.present? && results.first.code == terms)
  end

  def self.match_code(terms)
    /\A#{Setting["proposal_code_prefix"]}-\d\d\d\d-\d\d-(\d*)\z/.match(terms)
  end

  def self.for_summary
    summary = {}
    categories = ActsAsTaggableOn::Tag.category_names.sort
    geozones   = Geozone.names.sort

    groups = categories + geozones
    groups.each do |group|
      summary[group] = search(group).last_week.sort_by_confidence_score.limit(3)
    end
    summary
  end

  def total_votes
    cached_votes_up
  end

  def voters
    User.active.where(id: votes_for.voters)
  end

  def editable?
    total_votes <= Setting["max_votes_for_proposal_edit"].to_i
  end

  def editable_by?(user)
    author_id == user.id && editable?
  end

  def votable_by?(user)
    user && user.level_two_or_three_verified?
  end

  def retired?
    retired_at.present?
  end

  def register_vote(user, vote_value)
    if votable_by?(user) #TMP && !archived?
      vote_by(voter: user, vote: vote_value)
    end
  end

  def code
    "#{Setting["proposal_code_prefix"]}-#{created_at.strftime('%Y-%m')}-#{id}"
  end

  def after_commented
    save # updates the hot_score because there is a before_save
  end

  def calculate_hot_score
    self.hot_score = ScoreCalculator.hot_score(created_at,
                                               total_votes,
                                               total_votes,
                                               comments_count)
  end

  def calculate_confidence_score
    self.confidence_score = ScoreCalculator.confidence_score(total_votes, total_votes)
  end

  def after_hide
    self.tags.each{ |t| t.decrement_custom_counter_for('Proposal') }
  end

  def after_restore
    self.tags.each{ |t| t.increment_custom_counter_for('Proposal') }
  end

  def self.votes_needed_for_success
    Setting['votes_for_proposal_success'].to_i
  end

  def open_plenary?
    tag_list.include?('plenoabierto') &&
    created_at >= Date.parse("18-04-2016").beginning_of_day
  end

  def self.open_plenary_winners
    tagged_with('plenoabierto').
    by_date_range(open_plenary_dates).
    sort_by_confidence_score.
    limit(5)
  end

  def self.open_plenary_dates
    Date.parse("18-04-2016").beginning_of_day..Date.parse("21-04-2016").end_of_day
  end

  def successful?
    total_votes >= Proposal.votes_needed_for_success
  end

  def archived?
    self.created_at <= Setting["months_to_archive_proposals"].to_i.months.ago
  end

  def notifications
    proposal_notifications
  end

  def self.rank(proposal)
    return 0 if proposal.blank?
    connection.select_all(<<-SQL).first['rank']
      SELECT ranked.rank FROM (
        SELECT id, rank() OVER (ORDER BY confidence_score DESC)
        FROM proposals
      ) AS ranked
      WHERE id = #{proposal.id}
      SQL
  end

  def self.public_columns_for_api
    ["id",
     "title",
     "description",
     "external_url",
     "cached_votes_up",
     "comments_count",
     "hot_score",
     "confidence_score",
     "created_at",
     "summary",
     "video_url",
     "geozone_id",
     "retired_at",
     "retired_reason",
     "retired_explanation",
     "proceeding",
     "sub_proceeding"]
  end

  def public_for_api?
    return false if hidden?
    return false unless ["Derechos Humanos", nil].include?(proceeding)
    return true
  end

  def self.public_for_api
    where(hidden_at: nil)
      .where(['proposals.proceeding IS NULL or proposals.proceeding = ?', 'Derechos Humanos'])
  end

  protected

    def set_responsible_name
      if author && author.document_number?
        self.responsible_name = author.document_number
      end
    end

end
