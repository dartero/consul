class Fork
  class Github
    include ActiveModel::Model
    attr_accessor :fork

    def initialize(fork)
      @fork = fork
    end

    def diff_url
      "#{consul_url}...#{username}:master"
    end

    def files_changed
      github["files"].collect {|file| file["filename"]}
    end

    def lines_diff
      github["files"].inject(0) { |sum, file| sum + file["changes"] }
    end

    def last_commit
      github_cache("last_commit_#{name}") do
        response = JSON.parse(open(commits_url).read)
        response.first["commit"]["author"]["date"].to_date
      end
    end

    private

      def name
        fork.name
      end

      def username
        fork.repo.split("/")[-2]
      end

      def repo
        fork.repo.split("/")[-1]
      end

      def number_files_changed
        files_changed.count
      end

      def api_url
        "https://api.github.com"
      end

      def consul_api_url
        "#{api_url}/repos/consul/consul/compare/consul:master"
      end

      def consul_url
        "https://github.com/consul/consul/compare/master"
      end

      def compare_url
        "#{consul_api_url}...#{username}:master?#{auth}"
      end

      def commits_url
        "#{api_url}/repos/#{username}/#{repo}/commits?#{auth}"
      end

      def auth
        "access_token=#{access_token}"
      end

      def access_token
        "d2f93f66ea9c3c8e6900f55358022b2d24828878"
      end

      def github
        github_cache(name) do
          JSON.parse(open(compare_url).read)
        end
      end

      def github_cache(key, &block)
        Rails.cache.fetch("github/v1/#{key}", &block)
      end

  end
end