class Fork < ActiveRecord::Base
  delegate :last_commit, :lines_diff, :files_changed, :diff_url, to: :github

  def github
    Fork::Github.new(self)
  end

end