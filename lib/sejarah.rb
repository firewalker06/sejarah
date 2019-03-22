require "sejarah/version"
require "thor"
require "octokit"

module Sejarah
  class Error < StandardError; end

  class CLI < Thor
    desc "hello", "Call user name from GitHub"
    def hello
      repos.each do |repo|
        merged_issues_from(repo).each do |issue|
          @releases
          puts "- [#{issue.closed_at}] #{issue.html_url} #{issue.title}"
        end
      end
    end

    private

      def client
        @_client ||= Octokit::Client.new(access_token: ENV.fetch("GITHUB_ACCESS_TOKEN"))
      end

      def merged_issues_from(repo)
        client.get("search/issues?q=repo:#{repo}+is:merged&sort=updated&order=desc").items
      end

      def repos
        ENV.fetch("REPOS").split(",")
      end
  end
end
